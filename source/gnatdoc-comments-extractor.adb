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

with Libadalang.Analysis;             use Libadalang.Analysis;
with Libadalang.Common;               use Libadalang.Common;
with Langkit_Support.Slocs;           use Langkit_Support.Slocs;
with Langkit_Support.Text;            use Langkit_Support.Text;

with VSS.Characters;                  use VSS.Characters;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Character_Iterators; use VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;         use VSS.Strings.Conversions;

package body GNATdoc.Comments.Extractor is

   Ada_New_Line_Function : constant Line_Terminator_Set :=
     (CR | LF | CRLF => True, others => False);

   function Line_Count (Item : Text_Type) return Natural;
   --  Returns number of lines occupied by given segment of the text.

   ----------------
   -- Line_Count --
   ----------------

   function Line_Count (Item : Text_Type) return Natural is
      Lines : constant VSS.String_Vectors.Virtual_String_Vector :=
        To_Virtual_String (Item).Split_Lines (Ada_New_Line_Function);

   begin
      return Lines.Length;
   end Line_Count;

   -------------
   -- Extract --
   -------------

   function Extract
     (Node    : Libadalang.Analysis.Subp_Decl'Class;
      Options : Extractor_Options) return not null Structured_Comment_Access
   is
      Advanced_Groups : Boolean := False;

      function New_Advanced_Group
        (Parameters : Param_Spec'Class) return Boolean;
      --  Whether to start new group of parameters.

      ------------------------
      -- New_Advanced_Group --
      ------------------------

      function New_Advanced_Group
        (Parameters : Param_Spec'Class) return Boolean
      is
         Token : Token_Reference := Parameters.Token_Start;

      begin
         if not Advanced_Groups then
            return True;
         end if;

         Token := Previous (Token);

         --  Start new advanced group when whitespace contains at least one
         --  blank line

         if Kind (Data (Token)) = Ada_Whitespace then
            if Line_Count (Text (Token)) > 2 then
               return True;
            end if;
         end if;

         return False;
      end New_Advanced_Group;

      Decl_Node    : constant Subp_Decl   := Node.As_Subp_Decl;
      Aspects_Node : constant Aspect_Spec := Decl_Node.F_Aspects;
      Spec_Node    : constant Subp_Spec   := Decl_Node.F_Subp_Spec;
      Params_Node  : constant Params      := Spec_Node.F_Subp_Params;

      Previous_Group   : Section_Vectors.Vector;
      Group_Start_Line : Line_Number := 0;
      Group_End_Line   : Line_Number := 0;
      Raw_Section      : Section_Access;

   begin
      return Result : constant not null Structured_Comment_Access :=
        new Structured_Comment
      do
         --  Check whether empty lines are present inside parameter
         --  declaration block to enable advanced parameter group
         --  processing.

         for Token of Node.F_Subp_Spec.F_Subp_Params.Token_Range loop
            if Kind (Data (Token)) = Ada_Whitespace then
               if Line_Count (Text (Token)) > 2 then
                  Advanced_Groups := True;

                  exit;
               end if;
            end if;
         end loop;

         --  Create "raw" section to collect all documentation for subprogram,
         --  exact range is used to fill comments after the end of the
         --  subprogram specification and before the name of the first aspect
         --  association, thus, location of the "when" keyword is not
         --  significant.

         Raw_Section :=
           new Section'
             (Kind             => Raw,
              Name             => <>,
              Text             => <>,
              Exact_Start_Line =>
                (if Params_Node = No_Params
                 then Spec_Node.F_Subp_Name.Sloc_Range.Start_Line
                 else Params_Node.Sloc_Range.End_Line + 1),
              Exact_End_Line   =>
                (if Aspects_Node = No_Aspect_Spec
                 then 0
                 else Aspects_Node.F_Aspect_Assocs.First_Child.Sloc_Range
                 .Start_Line - 1),
              others           => <>);
         Result.Sections.Append (Raw_Section);

         --  Create sections of structured comment for parameters, compute
         --  line range to extract comments of each parameter.

         for Parameters_Group of Params_Node.F_Params loop
            declare
               Location : constant
                 Langkit_Support.Slocs.Source_Location_Range :=
                   Parameters_Group.Sloc_Range;

            begin
               if Group_Start_Line /= 0
                 and then New_Advanced_Group (Parameters_Group)
               then
                  Group_End_Line := Location.Start_Line - 1;

                  for Parameter of Previous_Group loop
                     Parameter.Group_Start_Line := Group_Start_Line;
                     Parameter.Group_End_Line   := Group_End_Line;
                  end loop;

                  Previous_Group.Clear;
               end if;

               for Id of Parameters_Group.F_Ids loop
                  declare
                     Parameter_Section : constant not null Section_Access :=
                       new Section'
                         (Kind             => Parameter,
                          Name             =>
                            To_Virtual_String (Id.F_Name.P_Canonical_Text),
                          Text             => <>,
                          Exact_Start_Line => Location.Start_Line,
                          Exact_End_Line   => Location.End_Line,
                          Group_Start_Line => 0,
                          Group_End_Line   => 0);

                  begin
                     Result.Sections.Append (Parameter_Section);
                     Previous_Group.Append (Parameter_Section);
                  end;
               end loop;

               Group_Start_Line := Location.End_Line + 1;
               Group_End_Line   := 0;
            end;
         end loop;

         --  Parse comments inside the subprogram declaration and fill
         --  text of raw and parameters sections.

         declare
            Location : Source_Location_Range;

         begin
            for Token of Node.Token_Range loop
               Location := Sloc_Range (Data (Token));

               if Kind (Data (Token)) = Ada_Comment then
                  for Section of Result.Sections loop
                     if Section.Kind in Raw | Parameter
                       and then
                         (Location.Start_Line
                            in Section.Exact_Start_Line
                                 .. Section.Exact_End_Line
                          or Location.Start_Line
                               in Section.Group_Start_Line
                                    .. Section.Group_End_Line)

                     then
                        if Advanced_Groups
                          and Location.Start_Line = Section.Group_Start_Line
                          and not Section.Text.Is_Empty
                        then
                           Section.Text.Append (Empty_Virtual_String);
                        end if;

                        Section.Text.Append (To_Virtual_String (Text (Token)));
                     end if;
                  end loop;
               end if;
            end loop;
         end;

         --  Process tokens after the subprogram declaration when subprogram
         --  documentataion was not found inside subprogram declaration.

         if Raw_Section.Text.Is_Empty then
            declare
               Token : Token_Reference := Decl_Node.Token_End;

            begin
               Token := Next (Token);

               loop
                  exit when Token = No_Token;

                  case Kind (Data (Token)) is
                     when Ada_Comment =>
                        Raw_Section.Text.Append
                          (To_Virtual_String (Text (Token)));

                     when Ada_Whitespace =>
                        exit when Line_Count (Text (Token)) > 2;

                     when others =>
                        exit;
                  end case;

                  Token := Next (Token);
               end loop;
            end;
         end if;

         --  Postprocess extracted text, for each group of lines, separated
         --  by empty line by remove of two minus signs and common leading
         --  whitespaces

         for Section of Result.Sections loop
            declare
               First_Line : Positive := 1;
               Last_Line  : Natural  := 0;
               Indent     : Character_Count;

            begin
               loop
                  for J in First_Line .. Section.Text.Length loop
                     exit when Section.Text (J).Is_Empty;

                     Last_Line := J;
                  end loop;

                  --  Compute common indentation level

                  Indent := Character_Count'Last;

                  for J in First_Line .. Last_Line loop
                     declare
                        Line     : constant Virtual_String :=
                          Section.Text (J);
                        Iterator : Character_Iterator :=
                          Line.Before_First_Character;
                        Success  : Boolean;

                     begin
                        --  Skip '--'

                        Success := Iterator.Forward;
                        pragma Assert
                          (Success and then Iterator.Element = '-');

                        Success := Iterator.Forward;
                        pragma Assert
                          (Success and then Iterator.Element = '-');

                        --  Lookup for first non-whitespace character

                        while Iterator.Forward loop
                           exit when Iterator.Element /= ' ';
                        end loop;

                        if Iterator.Is_Valid then
                           Indent :=
                             Character_Index'Min
                               (Indent, Iterator.Character_Index - 1);
                        end if;
                     end;
                  end loop;

                  --  Remove common indentation segment

                  for J in First_Line .. Last_Line loop
                     declare
                        Line     : constant Virtual_String :=
                          Section.Text (J);
                        Iterator : Character_Iterator :=
                          Line.At_First_Character;
                        Success  : Boolean;

                     begin
                        if Line.Character_Length > Indent then
                           for J in 1 .. Indent loop
                              Success := Iterator.Forward;
                           end loop;

                           Section.Text.Replace
                             (J,
                              Line.Slice (Iterator, Line.At_Last_Character));

                        else
                           Section.Text.Replace (J, Empty_Virtual_String);
                        end if;
                     end;
                  end loop;

                  First_Line := Last_Line + 2;

                  exit when Last_Line = Section.Text.Length;
               end loop;
            end;
         end loop;
      end return;
   end Extract;

end GNATdoc.Comments.Extractor;
