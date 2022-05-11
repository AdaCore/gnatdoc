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
with VSS.String_Vectors;              use VSS.String_Vectors;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Character_Iterators; use VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;         use VSS.Strings.Conversions;

package body GNATdoc.Comments.Extractor is

   type Section_Tag is (Param_Tag, Return_Tag, Exception_Tag, Enum_Tag);

   type Section_Tag_Flags is array (Section_Tag) of Boolean with Pack;

   Ada_New_Line_Function             : constant Line_Terminator_Set :=
     (CR | LF | CRLF => True, others => False);

   Ada_Identifier_Expression         : constant Virtual_String :=
     "[\p{L}\p{Nl}][\p{L}\p{Nl}\p{Mn}\p{Mc}\p{Nd}\p{Pc}]*";
   Ada_Character_Literal_Expression  : constant Virtual_String :=
     "'[\p{L}\p{M}\p{N}\p{P}\p{S}\p{Z}\p{Cn}]'";
   Ada_Optional_Separator_Expression : constant Virtual_String :=
     "[\p{Zs}\p{Cf}]*";

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
   --
   --  @param Decl_Node       Whole declaration
   --  @param Subp_Spec_Node  Subprogram specification
   --  @param Expr_Node       Expression of expression function
   --  @param Aspects_Node    List of aspects
   --  @param Options         Documentataion extraction options

   function Extract_Enumeration_Type_Documentation
     (Node    : Libadalang.Analysis.Type_Decl'Class;
      Options : Extractor_Options) return not null Structured_Comment_Access
     with Pre => Node.Kind = Ada_Type_Decl
                   and then Node.F_Type_Def.Kind = Ada_Enum_Type_Def;
   --  Extract documentation for type declaration.

   procedure Fill_Structured_Comment
     (Decl_Node        : Basic_Decl'Class;
      Advanced_Groups  : Boolean;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Documentation    : in out Structured_Comment'Class;
      Leading_Section  : out not null Section_Access;
      Trailing_Section : out not null Section_Access);
   --  Extract comments' text from the given declaration and fill sections
   --  of the provided structured comment. Also, creates raw sections for
   --  the leading and trailing comments and extract them into these sections.
   --
   --  @param Decl_Node           Whole declaration.
   --  @param Advanced_Groups
   --    Advanced processing of the groups: empty line is added at the and
   --    of the section's text when it is not empty and processing of the
   --    group comment is started.
   --  @param Last_Section
   --    Last section inside the declaration. If there are some comments after
   --    the declaration and its indentation is equal of deeper than the value
   --    of the Minimum_Indent parameter, this section is filled by these
   --    comments.
   --  @param Minimum_Indent      Minimum indentation to fill last section.
   --  @param Documentation       Structured comment to fill.
   --  @param Leading_Section     Leading raw text
   --  @param Trailing_Section    Trailing raw text.

   procedure Fill_Code_Snippet
     (Node          : Ada_Node'Class;
      Documentation : in out Structured_Comment'Class);
   --  Extract code snippet of declaration, remove all comments from it,
   --  and create code snippet section of the structured comment.

   procedure Remove_Comment_Start_And_Indentation
      (Documentation : in out Structured_Comment'Class);
   --  Postprocess extracted text, for each group of lines, separated by empty
   --  line, by remove of two minus signs and common leading whitespaces. For
   --  code snippet remove common leading whitespaces only.

   procedure Parse_Raw_Section
     (Raw_Section   : Section_Access;
      Allowed_Tags  : Section_Tag_Flags;
      Documentation : in out Structured_Comment'Class);
   --  Process raw documentation, fill sections and create description section.
   --
   --  @param Raw_Section    Raw section to process
   --  @param Allowed_Tags   Set of section tags to be processed
   --  @param Documentation  Structured comment to fill

   function Is_Ada_Separator (Item : Virtual_Character) return Boolean;
   --  Return True when given character is Ada's separator.
   --
   --  @param Item Character to be classified
   --  @return Whether given character is Ada's separator or not

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

         when Ada_Type_Decl =>
            return
              Extract_Enumeration_Type_Documentation
                (Node.As_Type_Decl, Options);

         when others =>
            raise Program_Error;
      end case;
   end Extract;

   --------------------------------------------
   -- Extract_Enumeration_Type_Documentation --
   --------------------------------------------

   function Extract_Enumeration_Type_Documentation
     (Node    : Libadalang.Analysis.Type_Decl'Class;
      Options : Extractor_Options) return not null Structured_Comment_Access
   is
      Type_Def_Node    : constant Type_Def'Class := Node.F_Type_Def;
      Enum_Node        : constant Enum_Type_Def'Class :=
        Type_Def_Node.As_Enum_Type_Def;
      Last_Section     : Section_Access;
      Minimum_Indent   : Column_Number           := 0;
      Leading_Section  : Section_Access;
      Trailing_Section : Section_Access;

   begin
      return Result : constant not null Structured_Comment_Access :=
        new Structured_Comment
      do
         for Literal of Enum_Node.F_Enum_Literals loop
            declare
               Literal_Name_Node : constant Name := Literal.F_Name.F_Name;
               Location          : constant Source_Location_Range :=
                 Literal.Sloc_Range;
               Literal_Section   : constant not null Section_Access :=
                 new Section'
                   (Kind             => Enumeration_Literal,
                    Name             =>
                      To_Virtual_String
                        (Text (Literal_Name_Node.Token_Start)),
                    Symbol           =>
                      To_Virtual_String
                        ((if Literal_Name_Node.Kind = Ada_Char_Literal
                         then To_Unbounded_Text
                           (Text (Literal_Name_Node.Token_Start))
                         else Literal_Name_Node.P_Canonical_Text)),
                    --  LAL: P_Canonical_Text do case conversion which
                    --  makes lowercase and uppercase character literals
                    --  undistingushable.
                    Exact_Start_Line => Location.Start_Line,
                    Exact_End_Line   => Location.End_Line,
                    Group_Start_Line => Location.End_Line + 1,
                    others           => <>);

            begin
               Result.Sections.Append (Literal_Section);

               if Last_Section /= null then
                  Last_Section.Group_End_Line := Location.Start_Line - 1;
               end if;

               --  Remember last section and its minimum indentation level.

               Last_Section   := Literal_Section;
               Minimum_Indent := Location.Start_Column;
            end;
         end loop;

         Fill_Structured_Comment
           (Decl_Node          => Node,
            Advanced_Groups    => False,
            Last_Section       => Last_Section,
            Minimum_Indent     => Minimum_Indent,
            Documentation      => Result.all,
            Leading_Section    => Leading_Section,
            Trailing_Section   => Trailing_Section);

         Fill_Code_Snippet (Node, Result.all);

         Remove_Comment_Start_And_Indentation (Result.all);

         declare
            Raw_Section : Section_Access;

         begin
            --  Select most appropriate section depending from the style and
            --  fallback.

            case Options.Style is
               when GNAT =>
                  if not Trailing_Section.Text.Is_Empty then
                     Raw_Section := Trailing_Section;

                  elsif Options.Fallback
                    and not Leading_Section.Text.Is_Empty
                  then
                     Raw_Section := Leading_Section;
                  end if;

               when Leading =>
                  if not Leading_Section.Text.Is_Empty then
                     Raw_Section := Leading_Section;

                  elsif Options.Fallback
                    and not Trailing_Section.Text.Is_Empty
                  then
                     Raw_Section := Trailing_Section;
                  end if;
            end case;

            Parse_Raw_Section
              (Raw_Section,
               (Enum_Tag => True, others => False),
               Result.all);
         end;
      end return;
   end Extract_Enumeration_Type_Documentation;

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
      Group_Start_Line           : Line_Number   := 0;
      Group_End_Line             : Line_Number   := 0;
      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;
      Intermediate_Lower_Section : Section_Access;
      Trailing_Section           : Section_Access;
      Last_Section               : Section_Access;
      Minimum_Indent             : Column_Number := 0;

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
                             others           => <>);

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

                        --  Remember section of the last parameter and its
                        --  indentation for extracting of the comment from
                        --  the last line of the declaration.

                        Last_Section   := Parameter_Section;
                        Minimum_Indent := Location.Start_Column;
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
                    others           => <>);
               Token           : Token_Reference := Returns_Node.Token_Start;

            begin
               --  "return" keyword may be located at previous line, include
               --  this line into the exact range of the return value

               while Token /= No_Token loop
                  if Kind (Data (Token)) = Ada_Return then
                     Location := Sloc_Range (Data (Token));
                     Returns_Section.Exact_Start_Line := Location.Start_Line;
                     Minimum_Indent := Location.Start_Column;

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

               --  Remember section of the return statement for extracting of
               --  the comment from the last line of the declaration.

               Last_Section   := Returns_Section;
            end;
         end if;

         --  Parse comments inside the subprogram declaration and fill
         --  text of raw, parameters and returns sections.

         Fill_Structured_Comment
           (Decl_Node        => Decl_Node,
            Advanced_Groups  => Advanced_Groups,
            Last_Section     => Last_Section,
            Minimum_Indent   => Minimum_Indent,
            Documentation    => Result.all,
            Leading_Section  => Leading_Section,
            Trailing_Section => Trailing_Section);

         --  Extract code snippet of declaration and remove all comments from
         --  it.

         Fill_Code_Snippet (Subp_Spec_Node, Result.all);

         --  Postprocess extracted text, for each group of lines, separated
         --  by empty line by remove of two minus signs and common leading
         --  whitespaces

         Remove_Comment_Start_And_Indentation (Result.all);

         --  Process raw documentation for subprogram, fill sections and create
         --  description section.

         declare
            Raw_Section : Section_Access;

         begin
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
                     end if;
                  end if;
            end case;

            Parse_Raw_Section
              (Raw_Section,
               (Param_Tag | Return_Tag | Exception_Tag => True,
                others                                 => False),
               Result.all);
         end;
      end return;
   end Extract_Subprogram_Documentation;

   -----------------------
   -- Fill_Code_Snippet --
   -----------------------

   procedure Fill_Code_Snippet
     (Node          : Ada_Node'Class;
      Documentation : in out Structured_Comment'Class)
   is
      Snippet_Section : Section_Access;
      Text            : Virtual_String_Vector;

   begin
      Text :=
        To_Virtual_String (Node.Text).Split_Lines (Ada_New_Line_Function);

      --  Indent first line correctly.

      declare
         Line : Virtual_String := Text (1);

      begin
         for J in 2 .. Node.Sloc_Range.Start_Column loop
            Line.Prepend (' ');
         end loop;

         Text.Replace (1, Line);
      end;

      --  Remove comments

      declare
         Line_Offset : constant Line_Number := Node.Sloc_Range.Start_Line - 1;
         Token       : Token_Reference      := Node.Token_End;

      begin
         loop
            Token := Previous (Token);

            exit when Token = Node.Token_Start;

            if Kind (Data (Token)) = Ada_Comment then
               declare
                  Location : constant Source_Location_Range :=
                    Sloc_Range (Data (Token));
                  Index    : constant Positive :=
                    Positive (Location.Start_Line - Line_Offset);
                  Line     : Virtual_String := Text (Index);
                  Iterator : Character_Iterator :=
                    Line.After_Last_Character;

               begin
                  --  Move iterator till first character before the
                  --  comment's start column.

                  while Iterator.Backward loop
                     exit when
                       Iterator.Character_Index
                         < Character_Index (Location.Start_Column);
                  end loop;

                  --  Rewind all whitespaces before the comment

                  while Iterator.Backward loop
                     exit when not Is_Ada_Separator (Iterator.Element);
                  end loop;

                  --  Remove comment and spaces before it from the line,
                  --  or remove whole line if after remove of the
                  --  comment's text it contains whitespaces only.

                  if Iterator.Has_Element then
                     Line :=
                       Line.Slice (Line.At_First_Character, Iterator);
                     Text.Replace (Index, Line);

                  else
                     Text.Delete (Index);
                  end if;
               end;
            end if;
         end loop;
      end;

      Snippet_Section :=
        new Section'
          (Kind => Snippet, Symbol => "ada", Text => Text, others => <>);
      Documentation.Sections.Append (Snippet_Section);
   end Fill_Code_Snippet;

   -----------------------------
   -- Fill_Structured_Comment --
   -----------------------------

   procedure Fill_Structured_Comment
     (Decl_Node        : Basic_Decl'Class;
      Advanced_Groups  : Boolean;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Documentation    : in out Structured_Comment'Class;
      Leading_Section  : out not null Section_Access;
      Trailing_Section : out not null Section_Access)
   is
      Node_Location : constant Source_Location_Range :=
        Decl_Node.Sloc_Range;
      Location      : Source_Location_Range;

   begin
      --  Extract comments inside the declaration and fill text of raw,
      --  parameters, returns, and literals sections.

      declare
         Token : Token_Reference := Decl_Node.Token_Start;

      begin
         while Token /= No_Token and Token /= Decl_Node.Token_End loop
            Location := Sloc_Range (Data (Token));

            if Kind (Data (Token)) = Ada_Comment then
               for Section of Documentation.Sections loop
                  if Section.Kind
                       in Raw | Parameter | Returns | Enumeration_Literal
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

            Token := Next (Token);
         end loop;
      end;

      --  Create leading section and process tokens before the declaration
      --  node.

      Leading_Section :=
        new Section'
          (Kind             => Raw,
           Symbol           => "<<LEADING>>",
           Name             => <>,
           Text             => <>,
           others           => <>);
      Documentation.Sections.Append (Leading_Section);

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

      --  Create trailing section and process tokens after the declaration
      --  node.

      Trailing_Section :=
        new Section'
          (Kind             => Raw,
           Symbol           => "<<TRAILING>>",
           Name             => <>,
           Text             => <>,
           others           => <>);
      Documentation.Sections.Append (Trailing_Section);

      declare
         Token   : Token_Reference := Decl_Node.Token_End;
         In_Last : Boolean := Last_Section /= null;

      begin
         loop
            Token := Next (Token);

            exit when Token = No_Token;

            case Kind (Data (Token)) is
               when Ada_Comment =>
                  if In_Last then
                     if Sloc_Range (Data (Token)).Start_Column
                          >= Minimum_Indent
                     then
                        Last_Section.Text.Append
                          (To_Virtual_String (Text (Token)));

                        goto Done;

                     else
                        In_Last := False;
                     end if;
                  end if;

                  Trailing_Section.Text.Append
                    (To_Virtual_String (Text (Token)));

                  <<Done>>

               when Ada_Whitespace =>
                  exit when Line_Count (Text (Token)) > 2;

               when others =>
                  exit;
            end case;
         end loop;
      end;
   end Fill_Structured_Comment;

   ----------------------
   -- Is_Ada_Separator --
   ----------------------

   function Is_Ada_Separator (Item : Virtual_Character) return Boolean is
   begin
      return Get_General_Category (Item) in Space_Separator | Format;
   end Is_Ada_Separator;

   -----------------------
   -- Parse_Raw_Section --
   -----------------------

   procedure Parse_Raw_Section
     (Raw_Section   : Section_Access;
      Allowed_Tags  : Section_Tag_Flags;
      Documentation : in out Structured_Comment'Class)
   is
      Tag_Matcher       : constant Regular_Expression :=
        To_Regular_Expression
          (Ada_Optional_Separator_Expression
           & "@(param|return|exception|enum)"
           & Ada_Optional_Separator_Expression);
      Parameter_Matcher : constant Regular_Expression :=
        To_Regular_Expression
          ("((?:" & Ada_Identifier_Expression
           & "|" & Ada_Character_Literal_Expression & "))"
           & Ada_Optional_Separator_Expression);

      Match             : Regular_Expression_Match;
      Current_Section   : Section_Access;
      Kind              : Section_Kind;
      Tag               : Section_Tag;
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
      Documentation.Sections.Append (Current_Section);

      --  Return when there is no raw section to parse

      if Raw_Section = null then
         return;
      end if;

      --  Process raw text

      for Line of Raw_Section.Text loop
         Skip_Line := False;

         Match := Tag_Matcher.Match (Line);

         if Match.Has_Match then
            if Match.Captured (1) = "param" then
               Tag  := Param_Tag;
               Kind := Parameter;

            elsif Match.Captured (1) = "return" then
               Tag  := Return_Tag;
               Kind := Returns;

            elsif Match.Captured (1) = "exception" then
               Tag  := Exception_Tag;
               Kind := Raised_Exception;

            elsif Match.Captured (1) = "enum" then
               Tag  := Enum_Tag;
               Kind := Enumeration_Literal;

            else
               raise Program_Error;
            end if;

            if not Allowed_Tags (Tag) then
               goto Default;
            end if;

            Line_Tail := Line.Tail_After (Match.Last_Marker);

            if Kind in Parameter | Raised_Exception | Enumeration_Literal then
               --  Lookup for name of the parameter/exception. Convert
               --  found name to canonical form.

               --  Match := Parameter_Matcher.Match (Line, Tail_First);
               --  ??? Not implemented

               Match := Parameter_Matcher.Match (Line_Tail);

               if not Match.Has_Match then
                  goto Default;
               end if;

               Name := Match.Captured (1);

               --  Compute symbol name. For character literals it is equal to
               --  name, for identifiers it is canonicalized name.

               Symbol :=
                 (if Name.Starts_With ("'")
                  then Name
                  else To_Virtual_String
                    (Fold_Case (To_Wide_Wide_String (Name)).Symbol));

               Line_Tail := Line_Tail.Tail_After (Match.Last_Marker);

            else
               Name.Clear;
               Symbol.Clear;
            end if;

            declare
               Found : Boolean := False;

            begin
               for Section of Documentation.Sections loop
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
                     Documentation.Sections.Append (Current_Section);

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

      --  Remove empty lines at the end of text of all sections

      for Section of Documentation.Sections loop
         while not Section.Text.Is_Empty
           and then Section.Text.Last_Element.Is_Empty
         loop
            Section.Text.Delete_Last;
         end loop;
      end loop;
   end Parse_Raw_Section;

   ------------------------------------------
   -- Remove_Comment_Start_And_Indentation --
   ------------------------------------------

   procedure Remove_Comment_Start_And_Indentation
      (Documentation : in out Structured_Comment'Class) is
   begin
      for Section of Documentation.Sections loop
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
                     if Section.Kind /= Snippet then
                        --  Skip '--' from all sections, but snippet.

                        Success := Iterator.Forward;
                        pragma Assert
                          (Success and then Iterator.Element = '-');

                        Success := Iterator.Forward;
                        pragma Assert
                          (Success and then Iterator.Element = '-');
                     end if;

                     --  Lookup for first non-whitespace character

                     while Iterator.Forward loop
                        exit when not Is_Ada_Separator (Iterator.Element);
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
   end Remove_Comment_Start_And_Indentation;

end GNATdoc.Comments.Extractor;
