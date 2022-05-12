------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2022, AdaCore                        --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with VSS.Strings;             use VSS.Strings;
with VSS.Strings.Conversions; use VSS.Strings.Conversions;

with Langkit_Support.Slocs;   use Langkit_Support.Slocs;
with Langkit_Support.Text;    use Langkit_Support.Text;
with Libadalang.Analysis;     use Libadalang.Analysis;
with Libadalang.Common;       use Libadalang.Common;

package body GNATdoc.Comments.Builders is

   use all type GNATdoc.Comments.Extractor.Documentation_Style;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self          : in out Abstract_Components_Builder'Class;
      Documentation : not null GNATdoc.Comments.Structured_Comment_Access;
      Options       : GNATdoc.Comments.Extractor.Extractor_Options;
      Node          : Libadalang.Analysis.Ada_Node'Class) is
   begin
      Self.Style            := Options.Style;
      Self.Documentation    := Documentation;
      Self.Location         := (0, 0, 0, 0);
      Self.Advanced_Groups  := False;
      Self.Group_Start_Line := 0;
      Self.Group_End_Line   := 0;
      Self.Next_Start_Line  := 0;
      Self.Last_Section     := null;
      Self.Minimum_Indent   := 0;

      --  Check whether an empty lines are present inside node's text
      --  to enable advanced group processing in GNAT style.

      if Self.Style = GNAT then
         if not Node.Is_Null then
            for Token of Node.Token_Range loop
               --  ??? Should it be replaced by explicit iteration due to
               --  inconsistency in LAL?

               if Kind (Data (Token)) = Ada_Whitespace then
                  declare
                     Location : constant Source_Location_Range :=
                       Sloc_Range (Data (Token));

                  begin
                     if Location.End_Line - Location.Start_Line > 1 then
                        Self.Advanced_Groups := True;

                        exit;
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end if;
   end Initialize;

   -----------------------------------
   -- Process_Component_Declaration --
   -----------------------------------

   procedure Process_Component_Declaration
     (Self : in out Abstract_Components_Builder'Class;
      Node : Libadalang.Analysis.Ada_Node'Class)
   is

      function New_Group return Boolean;
      --  Whether to start new group of components.

      ---------------
      -- New_Group --
      ---------------

      function New_Group return Boolean is
         Token : Token_Reference := Node.Token_Start;

      begin
         if not Self.Advanced_Groups then
            return True;
         end if;

         Token := Previous (Token);

         --  Start new advanced group when whitespace contains at least one
         --  blank line

         if Kind (Data (Token)) = Ada_Whitespace then
            declare
               Location : constant Source_Location_Range :=
                 Sloc_Range (Data (Token));

            begin
               if Location.End_Line - Location.Start_Line > 1 then
                  return True;
               end if;
            end;
         end if;

         return False;
      end New_Group;

   begin
      Self.Location := Node.Sloc_Range;

      if Self.Next_Start_Line /= 0 then
         Self.Group_Start_Line := Self.Next_Start_Line;
         Self.Group_End_Line   := 0;
      end if;

      case Self.Style is
         when GNAT =>
            if Self.Group_Start_Line /= 0 and then New_Group then
               Self.Group_End_Line := Self.Location.Start_Line - 1;

               for Item of Self.Previous_Group loop
                  Item.Group_Start_Line := Self.Group_Start_Line;
                  Item.Group_End_Line   := Self.Group_End_Line;
               end loop;

               Self.Previous_Group.Clear;
            end if;

         when Leading =>
            --  In leading style, additional comment for the parameter ends
            --  on previous line.

            Self.Group_End_Line := Self.Location.Start_Line - 1;
      end case;

      Self.Next_Start_Line := Self.Location.Start_Line + 1;
   end Process_Component_Declaration;

   ---------------------------
   -- Process_Defining_Name --
   ---------------------------

   procedure Process_Defining_Name
     (Self : in out Abstract_Components_Builder'Class;
      Kind : GNATdoc.Comments.Section_Kind;
      Node : Libadalang.Analysis.Defining_Name'Class)
   is
      New_Section : constant not null Section_Access :=
        new Section'
          (Kind             => Kind,
           Name             => To_Virtual_String (Text (Node.Token_Start)),
           Symbol           =>
             --  To_Virtual_String (Node.F_Name.P_Canonical_Text),
             To_Virtual_String
               ((if Node.F_Name.Kind = Ada_Char_Literal
                   then To_Unbounded_Text (Text (Node.Token_Start))
                   else Node.F_Name.P_Canonical_Text)),
           --  LAL: P_Canonical_Text do case conversion which
           --  makes lowercase and uppercase character literals
           --  undistingushable.
           Text             => <>,
           Exact_Start_Line => Self.Location.Start_Line,
           Exact_End_Line   => Self.Location.End_Line,
           others           => <>);

   begin
      Self.Documentation.Sections.Append (New_Section);
      Self.Previous_Group.Append (New_Section);

      if Self.Style = Leading then
         --  In leading style, set range to lookup additional comments for
         --  group.

         New_Section.Group_Start_Line := Self.Group_Start_Line;
         New_Section.Group_End_Line := Self.Group_End_Line;
      end if;

      --  Remember the last section and its indentation level for extracting
      --  of comments from the last line of the declaration.

      Self.Last_Section   := New_Section;
      Self.Minimum_Indent := Self.Location.Start_Column;
   end Process_Defining_Name;

end GNATdoc.Comments.Builders;
