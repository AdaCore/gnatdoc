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
with Langkit_Support.Symbols;         use Langkit_Support.Symbols;
with Langkit_Support.Text;            use Langkit_Support.Text;

with VSS.Characters;                  use VSS.Characters;
with VSS.Regular_Expressions;         use VSS.Regular_Expressions;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Character_Iterators; use VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;         use VSS.Strings.Conversions;

package body GNATdoc.Comments.Extractor is

   Ada_New_Line_Function             : constant Line_Terminator_Set :=
     (CR | LF | CRLF => True, others => False);

   Ada_Identifier_Expression         : constant Virtual_String :=
     "(?:\p{L}|\p{Nl})(?:\p{L}|\p{Nl}|\p{Mn}|\p{Mc}|\p{Nd}|\p{Pc})*";
   Ada_Optional_Separator_Expression : constant Virtual_String :=
     "(?:\p{Zs}|\p{Cf})*";

   function Line_Count (Item : Text_Type) return Natural;
   --  Returns number of lines occupied by given segment of the text.

   function Extract_Subprogram_Documentation
     (Decl_Node      : Libadalang.Analysis.Basic_Decl'Class;
      Subp_Spec_Node : Subp_Spec'Class;
      Expr_Node      : Expr'Class;
      Aspects_Node   : Aspect_Spec'Class;
      Options        : Extractor_Options)
      return not null Structured_Comment_Access;
   --  Extracts subprogram's documentation.

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
     (Node    : Libadalang.Analysis.Basic_Decl'Class;
      Options : Extractor_Options) return not null Structured_Comment_Access is
   begin
      case Node.Kind is
         when Ada_Abstract_Subp_Decl | Ada_Subp_Decl =>
            return
              Extract_Subprogram_Documentation
                (Decl_Node      => Node,
                 Subp_Spec_Node => Node.As_Classic_Subp_Decl.F_Subp_Spec,
                 Expr_Node      => No_Expr,
                 Aspects_Node   => Node.F_Aspects,
                 Options        => Options);

         when Ada_Expr_Function =>
            return
              Extract_Subprogram_Documentation
                (Decl_Node      => Node,
                 Subp_Spec_Node => Node.As_Base_Subp_Body.F_Subp_Spec,
                 Expr_Node      => Node.As_Expr_Function.F_Expr,
                 Aspects_Node   => Node.F_Aspects,
                 Options        => Options);

         when Ada_Null_Subp_Decl =>
            return
              Extract_Subprogram_Documentation
                (Decl_Node      => Node,
                 Subp_Spec_Node => Node.As_Base_Subp_Body.F_Subp_Spec,
                 Expr_Node      => No_Expr,
                 Aspects_Node   => Node.F_Aspects,
                 Options        => Options);

         when others =>
            raise Program_Error;
      end case;
   end Extract;

   --------------------------------------
   -- Extract_Subprogram_Documentation --
   --------------------------------------

   function Extract_Subprogram_Documentation
     (Decl_Node      : Libadalang.Analysis.Basic_Decl'Class;
      Subp_Spec_Node : Subp_Spec'Class;
      Expr_Node      : Expr'Class;
      Aspects_Node   : Aspect_Spec'Class;
      Options        : Extractor_Options)
      return not null Structured_Comment_Access
   is
      Advanced_Groups : Boolean := False;

      function New_Advanced_Group
        (Parameters : Param_Spec'Class) return Boolean;
      --  Whether to start new group of parameters.

      --------------------------------
      -- Intermediate_Section_Range --
      --------------------------------

      procedure Intermediate_Section_Range
        (Subp_Spec_Node   : Subp_Spec'Class;
         Params_Node      : Params'Class;
         Returns_Node     : Type_Expr'Class;
         Expr_Node        : Expr'Class;
         Aspects_Node     : Aspect_Spec'Class;
         Upper_Start_Line : out Line_Number;
         Upper_End_Line   : out Line_Number;
         Lower_Start_Line : out Line_Number;
         Lower_End_Line   : out Line_Number);
      --  Range of the "intermediate" section for subprogram.

      --------------------------------
      -- Intermediate_Section_Range --
      --------------------------------

      procedure Intermediate_Section_Range
        (Subp_Spec_Node   : Subp_Spec'Class;
         Params_Node      : Params'Class;
         Returns_Node     : Type_Expr'Class;
         Expr_Node        : Expr'Class;
         Aspects_Node     : Aspect_Spec'Class;
         Upper_Start_Line : out Line_Number;
         Upper_End_Line   : out Line_Number;
         Lower_Start_Line : out Line_Number;
         Lower_End_Line   : out Line_Number) is
      begin
         if Returns_Node /= No_Type_Expr then
            --  For any functions, intermediate section starts after the
            --  return type of the function.

            Upper_Start_Line := Returns_Node.Sloc_Range.End_Line + 1;

         elsif Params_Node /= No_Params then
            --  For procedures with parameters, intermediate section starts
            --  after the parameters.

            Upper_Start_Line := Params_Node.Sloc_Range.End_Line + 1;

         else
            --  For parameterless procedures, intermadiate section starts
            --  after the procedure's name identifier.

            Upper_Start_Line :=
              Subp_Spec_Node.F_Subp_Name.Sloc_Range.Start_Line;
         end if;

         if Aspects_Node /= No_Aspect_Spec then
            --  When subprogram has aspects, intermediate section ends before
            --  the first aspect.

            Upper_End_Line :=
              Aspects_Node.F_Aspect_Assocs.First_Child.Sloc_Range.Start_Line
                - 1;

         else
            Upper_End_Line := 0;
         end if;

         if Expr_Node /= No_Expr then
            --  When function has expression, initialize lower intermediate
            --  section to be text between expression function and aspects.

            Lower_Start_Line := Expr_Node.Sloc_Range.End_Line + 1;
            Lower_End_Line := Upper_End_Line;

            --  ... and limit upper section till expression.

            Upper_End_Line := Expr_Node.Sloc_Range.Start_Line - 1;

         else
            Lower_Start_Line := 0;
            Lower_End_Line   := 0;
         end if;
      end Intermediate_Section_Range;

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

      Params_Node  : constant Params    := Subp_Spec_Node.F_Subp_Params;
      Returns_Node : constant Type_Expr := Subp_Spec_Node.F_Subp_Returns;

      Previous_Group             : Section_Vectors.Vector;
      Group_Start_Line           : Line_Number := 0;
      Group_End_Line             : Line_Number := 0;
      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;
      Intermediate_Lower_Section : Section_Access;
      Trailing_Section           : Section_Access;

   begin
      return Result : constant not null Structured_Comment_Access :=
        new Structured_Comment
      do
         --  Check whether empty lines are present inside parameter
         --  declaration block to enable advanced parameter group
         --  processing in GNAT style.

         if Options.Style = GNAT then
            if Params_Node /= No_Params then
               for Token of Params_Node.Token_Range loop
                  if Kind (Data (Token)) = Ada_Whitespace then
                     if Line_Count (Text (Token)) > 2 then
                        Advanced_Groups := True;

                        exit;
                     end if;
                  end if;
               end loop;
            end if;
         end if;

         --  Create "raw" section to collect all documentation for subprogram,
         --  exact range is used to fill comments after the end of the
         --  subprogram specification and before the name of the first aspect
         --  association, thus, location of the "when" keyword is not
         --  significant.

         Intermediate_Upper_Section :=
           new Section'
             (Kind             => Raw,
              Symbol           => "<<INTERMEDIATE UPPER>>",
              Name             => <>,
              Text             => <>,
              others           => <>);
         Intermediate_Lower_Section :=
           new Section'
             (Kind             => Raw,
              Symbol           => "<<INTERMEDIATE LOWER>>",
              Name             => <>,
              Text             => <>,
              others           => <>);
         Intermediate_Section_Range
           (Subp_Spec_Node,
            Params_Node,
            Returns_Node,
            Expr_Node,
            Aspects_Node,
            Intermediate_Upper_Section.Exact_Start_Line,
            Intermediate_Upper_Section.Exact_End_Line,
            Intermediate_Lower_Section.Exact_Start_Line,
            Intermediate_Lower_Section.Exact_End_Line);
         Result.Sections.Append (Intermediate_Upper_Section);
         Result.Sections.Append (Intermediate_Lower_Section);

         --  Create sections of structured comment for parameters, compute
         --  line range to extract comments of each parameter.

         if Options.Style = Leading then
            --  In leading style, additional comment for the first parameter
            --  started on the next line after subprogram's name.

            Group_Start_Line :=
              Subp_Spec_Node.F_Subp_Name.Sloc_Range.End_Line + 1;
         end if;

         if Params_Node /= No_Params then
            for Parameters_Group of Params_Node.F_Params loop
               declare
                  Location : constant
                    Langkit_Support.Slocs.Source_Location_Range :=
                      Parameters_Group.Sloc_Range;

               begin
                  case Options.Style is
                     when GNAT =>
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

                     when Leading =>
                        --  In leading style, additional comment for the
                        --  parameter ends on previous line.

                        Group_End_Line :=
                          Parameters_Group.Sloc_Range.Start_Line - 1;
                  end case;

                  for Id of Parameters_Group.F_Ids loop
                     declare
                        Parameter_Section : constant not null Section_Access :=
                          new Section'
                            (Kind             => Parameter,
                             Name             =>
                               To_Virtual_String (Text (Id.Token_Start)),
                             Symbol           =>
                               To_Virtual_String (Id.F_Name.P_Canonical_Text),
                             Text             => <>,
                             Exact_Start_Line => Location.Start_Line,
                             Exact_End_Line   => Location.End_Line,
                             Group_Start_Line => 0,
                             Group_End_Line   => 0);

                     begin
                        Result.Sections.Append (Parameter_Section);
                        Previous_Group.Append (Parameter_Section);

                        if Options.Style = Leading then
                           --  In leading style, set range to lookup
                           --  additional comments for the parameters.

                           Parameter_Section.Group_Start_Line :=
                             Group_Start_Line;
                           Parameter_Section.Group_End_Line := Group_End_Line;
                        end if;
                     end;
                  end loop;

                  Group_Start_Line := Location.End_Line + 1;
                  Group_End_Line   := 0;
               end;
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
                    Group_Start_Line => 0,
                    Group_End_Line   => 0);
               Token           : Token_Reference := Returns_Node.Token_Start;

            begin
               --  "return" keyword may be located at previous line, include
               --  this line into the exact range of the return value

               while Token /= No_Token loop
                  if Kind (Data (Token)) = Ada_Return then
                     Location := Sloc_Range (Data (Token));
                     Returns_Section.Exact_Start_Line := Location.Start_Line;

                     exit;
                  end if;

                  Token := Previous (Token);
               end loop;

               if Options.Style = Leading then
                  --  In leading style, set attitional range to lookup
                  --  comments.

                  Returns_Section.Group_Start_Line := Group_Start_Line;
                  Returns_Section.Group_End_Line :=
                    Returns_Section.Exact_Start_Line - 1;
               end if;

               Result.Sections.Append (Returns_Section);
            end;
         end if;

         --  Parse comments inside the subprogram declaration and fill
         --  text of raw, parameters and returns sections.

         declare
            Location : Source_Location_Range;

         begin
            for Token of Decl_Node.Token_Range loop
               Location := Sloc_Range (Data (Token));

               if Kind (Data (Token)) = Ada_Comment then
                  for Section of Result.Sections loop
                     if Section.Kind in Raw | Parameter | Returns
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

         --  Process tokens before the subprogram declaration.

         Leading_Section :=
           new Section'
             (Kind             => Raw,
              Symbol           => "<<LEADING>>",
              Name             => <>,
              Text             => <>,
              others           => <>);
         Result.Sections.Append (Leading_Section);

         declare
            Token : Token_Reference := Decl_Node.Token_Start;

         begin
            loop
               Token := Previous (Token);

               exit when Token = No_Token;

               case Kind (Data (Token)) is
                  when Ada_Comment =>
                     Leading_Section.Text.Prepend
                       (To_Virtual_String (Text (Token)));

                  when Ada_Whitespace =>
                     exit when Line_Count (Text (Token)) > 2;

                  when others =>
                     exit;
               end case;
            end loop;
         end;

         --  Process tokens after the subprogram declaration.

         Trailing_Section :=
           new Section'
             (Kind             => Raw,
              Symbol           => "<<TRAILING>>",
              Name             => <>,
              Text             => <>,
              others           => <>);
         Result.Sections.Append (Trailing_Section);

         declare
            Token : Token_Reference := Decl_Node.Token_End;
            Start : constant Line_Number :=
              Sloc_Range (Data (Token)).Start_Line
                + (if Params_Node = No_Params
                     and Returns_Node = No_Type_Expr then 0 else 1);
            --  Start line of the documentation, for parameterless procedure
            --  it starts at the last line of the subprogram specification,
            --  otherwise last line of the subprogram specification is
            --  reserved for description of the parameter/return value.

         begin
            loop
               Token := Next (Token);

               exit when Token = No_Token;

               case Kind (Data (Token)) is
                  when Ada_Comment =>
                     if Sloc_Range (Data (Token)).Start_Line >= Start then
                        Trailing_Section.Text.Append
                          (To_Virtual_String (Text (Token)));
                     end if;

                  when Ada_Whitespace =>
                     exit when Line_Count (Text (Token)) > 2;

                  when others =>
                     exit;
               end case;
            end loop;
         end;

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
                           exit when Get_General_Category (Iterator.Element)
                                       not in Space_Separator | Format;
                        end loop;

                        if Iterator.Has_Element then
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

                           Section.Text.Replace (J, Line.Tail_From (Iterator));

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

         --  Process raw documentation for subprogram, fill sections and create
         --  description section.

         declare
            Tag_Matcher       : constant Regular_Expression :=
              To_Regular_Expression
                (Ada_Optional_Separator_Expression
                 & "@(param|return|exception)"
                 & Ada_Optional_Separator_Expression);
            Parameter_Matcher : constant Regular_Expression :=
              To_Regular_Expression
                ("(" & Ada_Identifier_Expression & ")"
                   & Ada_Optional_Separator_Expression);
            Match             : Regular_Expression_Match;
            Raw_Section       : Section_Access;
            Current_Section   : Section_Access;
            Kind              : Section_Kind;
            Name              : Virtual_String;
            Symbol            : Virtual_String;
            Line_Tail         : Virtual_String;
            Skip_Line         : Boolean;

         begin
            pragma Assert (Tag_Matcher.Is_Valid);
            pragma Assert (Parameter_Matcher.Is_Valid);

            --  Create "Description" section

            Current_Section :=
              new Section'(Kind => Description, others => <>);
            Result.Sections.Append (Current_Section);

            --  Select most appropriate section depending from the style and
            --  fallback.

            case Options.Style is
               when GNAT =>
                  if not Intermediate_Upper_Section.Text.Is_Empty then
                     Raw_Section := Intermediate_Upper_Section;

                  elsif not Intermediate_Lower_Section.Text.Is_Empty then
                     Raw_Section := Intermediate_Lower_Section;

                  elsif not Trailing_Section.Text.Is_Empty then
                     Raw_Section := Trailing_Section;

                  elsif Options.Fallback
                    and not Leading_Section.Text.Is_Empty
                  then
                     Raw_Section := Leading_Section;

                  else
                     return;
                  end if;

               when Leading =>
                  if not Leading_Section.Text.Is_Empty then
                     Raw_Section := Leading_Section;

                  elsif Options.Fallback then
                     if Intermediate_Upper_Section.Text.Is_Empty then
                        Raw_Section := Intermediate_Upper_Section;

                     elsif not Intermediate_Lower_Section.Text.Is_Empty then
                        Raw_Section := Intermediate_Lower_Section;

                     elsif not Trailing_Section.Text.Is_Empty then
                        Raw_Section := Trailing_Section;

                     else
                        return;
                     end if;

                  else
                     return;
                  end if;
            end case;

            --  Process raw text

            for Line of Raw_Section.Text loop
               Skip_Line := False;

               Match := Tag_Matcher.Match (Line);

               if Match.Has_Match then
                  if Match.Captured (1) = "param" then
                     Kind := Parameter;

                  elsif Match.Captured (1) = "return" then
                     Kind := Returns;

                  elsif Match.Captured (1) = "exception" then
                     Kind := Raised_Exception;

                  else
                     raise Program_Error;
                  end if;

                  Line_Tail := Line.Tail_After (Match.Last_Marker);

                  if Kind in Parameter | Raised_Exception then
                     --  Lookup for name of the parameter/exception. Convert
                     --  found name to canonical form.

                     --  Match := Parameter_Matcher.Match (Line, Tail_First);
                     --  ??? Not implemented

                     Match := Parameter_Matcher.Match (Line_Tail);

                     if not Match.Has_Match then
                        goto Default;
                     end if;

                     Name := Match.Captured (1);
                     Symbol :=
                       To_Virtual_String
                        (Fold_Case (To_Wide_Wide_String (Name)).Symbol);

                     Line_Tail := Line_Tail.Tail_After (Match.Last_Marker);

                  else
                     Name.Clear;
                     Symbol.Clear;
                  end if;

                  declare
                     Found : Boolean := False;

                  begin
                     for Section of Result.Sections loop
                        if Section.Kind = Kind and Section.Symbol = Symbol then
                           Current_Section := Section;
                           Found := True;

                           exit;
                        end if;
                     end loop;

                     if not Found then
                        if Kind = Raised_Exception then
                           Current_Section :=
                             new Section'
                               (Kind   => Raised_Exception,
                                Name   => Name,
                                Symbol => Symbol,
                                others => <>);
                           Result.Sections.Append (Current_Section);

                        else
                           goto Default;
                        end if;

                     else
                        if not Current_Section.Text.Is_Empty then
                           Current_Section.Text.Append (Empty_Virtual_String);
                        end if;
                     end if;
                  end;

                  Skip_Line := True;

                  if not Line_Tail.Is_Empty then
                     Current_Section.Text.Append (Line_Tail);
                  end if;
               end if;

               <<Default>>

               if not Skip_Line then
                  Current_Section.Text.Append (Line);
               end if;
            end loop;
         end;

         --  Remove empty lines at the end of text of all sections

         for Section of Result.Sections loop
            while not Section.Text.Is_Empty
              and then Section.Text.Last_Element.Is_Empty
            loop
               Section.Text.Delete_Last;
            end loop;
         end loop;
      end return;
   end Extract_Subprogram_Documentation;

end GNATdoc.Comments.Extractor;
