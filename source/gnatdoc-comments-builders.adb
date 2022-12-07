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

with VSS.Strings;                use VSS.Strings;
with VSS.Strings.Conversions;    use VSS.Strings.Conversions;

with Langkit_Support.Slocs;      use Langkit_Support.Slocs;
with Langkit_Support.Text;       use Langkit_Support.Text;
with Libadalang.Analysis;        use Libadalang.Analysis;
with Libadalang.Common;          use Libadalang.Common;

with GNATdoc.Comments.Utilities; use GNATdoc.Comments.Utilities;

package body GNATdoc.Comments.Builders is

   use all type GNATdoc.Comments.Options.Documentation_Style;

   -----------------------------
   -- Fill_Structured_Comment --
   -----------------------------

   procedure Fill_Structured_Comment
     (Self    : in out Abstract_Components_Builder'Class;
      Node    : Basic_Decl'Class;
      Pattern : VSS.Regular_Expressions.Regular_Expression)
   is
      Location : Source_Location_Range;

   begin
      --  Extract comments inside the declaration and fill text of raw,
      --  parameters, returns, and literals sections.

      declare
         Token : Token_Reference := Node.Token_Start;

      begin
         while Token /= No_Token and Token /= Node.Token_End loop
            Location := Sloc_Range (Data (Token));

            if Kind (Data (Token)) = Ada_Comment then
               for Section of Self.Documentation.Sections loop
                  if Section.Kind
                       in Raw | Enumeration_Literal | Field
                            | Parameter | Returns | Formal
                    and then
                      (Location.Start_Line
                         in Section.Exact_Start_Line
                              .. Section.Exact_End_Line
                       or Location.Start_Line
                            in Section.Group_Start_Line
                                 .. Section.Group_End_Line)

                  then
                     if Self.Advanced_Groups
                       and Location.Start_Line = Section.Group_Start_Line
                       and not Section.Text.Is_Empty
                     then
                        Section.Text.Append (Empty_Virtual_String);
                     end if;

                     Append_Documentation_Line
                       (Section.Text, Text (Token), Pattern);
                  end if;
               end loop;
            end if;

            Token := Next (Token);
         end loop;
      end;
   end Fill_Structured_Comment;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Self          : in out Abstract_Components_Builder'Class;
      Documentation : not null GNATdoc.Comments.Structured_Comment_Access;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
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

         --  Start new advanced group when whitespace contains at least one
         --  blank line

         Token := Previous (Token);

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

         --  Start new advanced group when there is comment present before
         --  the node

         Token := Previous (Token);

         if Kind (Data (Token)) = Ada_Comment then
            return True;
         end if;

         return False;
      end New_Group;

   begin
      Self.Location := Node.Sloc_Range;

      case Self.Style is
         when GNAT =>
            if New_Group then
               Self.Restart_Component_Group (Self.Location.Start_Line);
            end if;

         when Leading =>
            --  In leading style, additional comment for the parameter ends
            --  on previous line.

            if Self.Next_Start_Line /= 0 then
               Self.Group_Start_Line := Self.Next_Start_Line;
            end if;

            Self.Group_End_Line := Self.Location.Start_Line - 1;
      end case;

      Self.Next_Start_Line := Self.Location.End_Line + 1;
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

   -----------------------------
   -- Restart_Component_Group --
   -----------------------------

   procedure Restart_Component_Group
     (Self       : in out Abstract_Components_Builder'Class;
      Start_Line : Langkit_Support.Slocs.Line_Number) is
   begin
      case Self.Style is
         when GNAT =>
            if Self.Next_Start_Line /= 0 then
               for Item of Self.Previous_Group loop
                  Item.Group_Start_Line := Self.Next_Start_Line;
                  Item.Group_End_Line   := Start_Line - 1;
               end loop;

               Self.Previous_Group.Clear;
               Self.Group_Start_Line := 0;
               Self.Group_End_Line   := 0;
            end if;

         when Leading =>
            null;
      end case;

      Self.Next_Start_Line := 0;
   end Restart_Component_Group;

end GNATdoc.Comments.Builders;
