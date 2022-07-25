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

with Libadalang.Common;

package body GNATdoc.Comments.Builders.Subprograms is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -----------
   -- Build --
   -----------

   procedure Build
     (Self            : in out Subprogram_Components_Builder;
      Documentation   : not null GNATdoc.Comments.Structured_Comment_Access;
      Options         : GNATdoc.Comments.Options.Extractor_Options;
      Node            : Libadalang.Analysis.Subp_Spec'Class;
      Advanced_Groups : out Boolean;
      Last_Section    : out GNATdoc.Comments.Section_Access;
      Minimum_Indent  : out Langkit_Support.Slocs.Column_Number)
   is
      use all type GNATdoc.Comments.Options.Documentation_Style;
      use type Langkit_Support.Slocs.Line_Number;

      Params_Node  : constant Params    := Node.F_Subp_Params;
      Returns_Node : constant Type_Expr := Node.F_Subp_Returns;

   begin
      Self.Initialize (Documentation, Options, Node);

      if Self.Style = Leading then
         if not Node.F_Subp_Name.Is_Null then
            --  In leading style, additional comment for the first parameter
            --  started on the next line after subprogram's name if present...

            Self.Group_Start_Line := Node.F_Subp_Name.Sloc_Range.End_Line + 1;

         else
            --  ... or at the first line of the subprogram specification of
            --  access to subprogram type.

            Self.Group_Start_Line := Node.Sloc_Range.Start_Line;
         end if;
      end if;

      --  Create sections of structured comment for parameters, compute
      --  line range to extract comments of each parameter.

      if Params_Node /= No_Params then
         for Parameter_Specification of Params_Node.F_Params loop
            Self.Process_Component_Declaration (Parameter_Specification);

            for Name of Parameter_Specification.F_Ids loop
               Self.Process_Defining_Name (Parameter, Name);
            end loop;
         end loop;
      end if;

      --  Create section of the structured comment for the return value of
      --  the function.

      if Returns_Node /= No_Type_Expr then
         declare
            Location        :
              Langkit_Support.Slocs.Source_Location_Range :=
                Returns_Node.Sloc_Range;
            Returns_Section : constant not null Section_Access :=
              new Section'
                (Kind             => Returns,
                 Name             => <>,
                 Symbol           => <>,
                 Text             => <>,
                 Exact_Start_Line => Location.Start_Line,
                 Exact_End_Line   => Location.End_Line,
                 others           => <>);
            Token           : Token_Reference := Returns_Node.Token_Start;

         begin
            --  "return" keyword may be located at previous line, include
            --  this line into the exact range of the return value

            while Token /= No_Token loop
               if Kind (Data (Token)) = Ada_Return then
                  Location := Sloc_Range (Data (Token));
                  Returns_Section.Exact_Start_Line := Location.Start_Line;
                  Self.Minimum_Indent := Location.Start_Column;

                  exit;
               end if;

               Token := Previous (Token);
            end loop;

            if Options.Style = Leading then
               --  In leading style, set attitional range to lookup
               --  comments.

               Returns_Section.Group_Start_Line :=
                 (if Self.Next_Start_Line /= 0
                    then Self.Next_Start_Line
                    else Self.Group_Start_Line);
               Returns_Section.Group_End_Line :=
                 Returns_Section.Exact_Start_Line - 1;
            end if;

            Self.Documentation.Sections.Append (Returns_Section);

            --  Remember section of the return statement for extracting of
            --  the comment from the last line of the declaration.

            Self.Last_Section := Returns_Section;
         end;
      end if;

      Advanced_Groups := Self.Advanced_Groups;
      Last_Section    := Self.Last_Section;
      Minimum_Indent  := Self.Minimum_Indent;
   end Build;

end GNATdoc.Comments.Builders.Subprograms;
