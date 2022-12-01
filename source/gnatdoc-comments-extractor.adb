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
with VSS.Characters.Latin;            use VSS.Characters.Latin;
with VSS.Regular_Expressions;         use VSS.Regular_Expressions;
with VSS.String_Vectors;              use VSS.String_Vectors;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Character_Iterators; use VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;         use VSS.Strings.Conversions;

with GNATdoc.Comments.Builders.Enumerations;
with GNATdoc.Comments.Builders.Generics;
with GNATdoc.Comments.Builders.Records;
with GNATdoc.Comments.Builders.Subprograms;

package body GNATdoc.Comments.Extractor is

   use all type GNATdoc.Comments.Options.Documentation_Style;

   type Section_Tag is
     (Param_Tag,
      Return_Tag,
      Exception_Tag,
      Enum_Tag,
      Member_Tag,
      Formal_Tag,
      Private_Tag);

   type Section_Tag_Flags is array (Section_Tag) of Boolean with Pack;

   Ada_New_Line_Function             : constant Line_Terminator_Set :=
     (CR | LF | CRLF => True, others => False);

   Ada_Identifier_Expression         : constant Virtual_String :=
     "[\p{L}\p{Nl}][\p{L}\p{Nl}\p{Mn}\p{Mc}\p{Nd}\p{Pc}]*";
   Ada_Character_Literal_Expression  : constant Virtual_String :=
     "'[\p{L}\p{M}\p{N}\p{P}\p{S}\p{Z}\p{Cn}]'";
   Ada_Optional_Separator_Expression : constant Virtual_String :=
     "[\p{Zs}\p{Cf}]*";

   procedure Extract_Base_Package_Decl_Documentation
     (Basic_Decl_Node        : Libadalang.Analysis.Basic_Decl'Class;
      Base_Package_Decl_Node : Libadalang.Analysis.Base_Package_Decl'Class;
      Options                : GNATdoc.Comments.Options.Extractor_Options;
      Documentation          : in out Structured_Comment'Class);
   --  Common code to extract documentation for ordinary and generic package
   --  declarations.

   procedure Extract_Generic_Package_Decl_Documentation
     (Node          : Libadalang.Analysis.Generic_Package_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class);

   procedure Extract_Subprogram_Documentation
     (Decl_Node     : Libadalang.Analysis.Basic_Decl'Class;
      Spec_Node     : Libadalang.Analysis.Base_Subp_Spec'Class;
      Expr_Node     : Expr'Class;
      Aspects_Node  : Aspect_Spec'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
     with Pre =>
       Spec_Node.Kind in Ada_Subp_Spec | Ada_Entry_Spec;
   --  Extracts subprogram's documentation.
   --
   --  @param Decl_Node       Whole declaration
   --  @param Subp_Spec_Node  Subprogram specification
   --  @param Expr_Node       Expression of expression function
   --  @param Aspects_Node    List of aspects
   --  @param Options         Documentataion extraction options

   procedure Extract_Enumeration_Type_Documentation
     (Node          : Libadalang.Analysis.Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
     with Pre => Node.Kind in Ada_Type_Decl
                   and then Node.F_Type_Def.Kind = Ada_Enum_Type_Def;
   --  Extract documentation for type declaration.

   procedure Extract_Record_Type_Documentation
     (Node          : Libadalang.Analysis.Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
     with Pre =>
       (Node.Kind in Ada_Type_Decl
        and then Node.F_Type_Def.Kind = Ada_Record_Type_Def)
       or (Node.Kind in Ada_Type_Decl
           and then Node.F_Type_Def.Kind = Ada_Derived_Type_Def
           and then not Node.F_Type_Def.As_Derived_Type_Def
                          .F_Record_Extension.Is_Null);
   --  Extract documentation for record type declaration.

   procedure Extract_Simple_Declaration_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
     with Pre => Node.Kind in Ada_Exception_Decl
                   | Ada_Generic_Package_Instantiation
                   | Ada_Generic_Subp_Instantiation
                   | Ada_Number_Decl
                   | Ada_Object_Decl
                   | Ada_Package_Renaming_Decl
                   | Ada_Subtype_Decl
     or (Node.Kind in Ada_Type_Decl
         and then Node.As_Type_Decl.F_Type_Def.Kind in Ada_Array_Type_Def
                    | Ada_Interface_Type_Def
                    | Ada_Mod_Int_Type_Def
                    | Ada_Private_Type_Def
                    | Ada_Signed_Int_Type_Def
                    | Ada_Type_Access_Def)
     or (Node.Kind in Ada_Type_Decl
         and then Node.As_Type_Decl.F_Type_Def.Kind = Ada_Derived_Type_Def
         and then Node.As_Type_Decl.F_Type_Def.As_Derived_Type_Def
                    .F_Record_Extension.Is_Null);
   --  Extract documentation for simple declaration (declarations that doesn't
   --  contains components).

   procedure Extract_Single_Task_Decl_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Decl          : Libadalang.Analysis.Task_Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class);
   --  Extract documentation for single task declaration.

   procedure Fill_Structured_Comment
     (Decl_Node       : Basic_Decl'Class;
      Advanced_Groups : Boolean;
      Pattern         : VSS.Regular_Expressions.Regular_Expression;
      Documentation   : in out Structured_Comment'Class);
   --  Extract comments' text from the given declaration and fill sections
   --  of the provided structured comment. Also, creates raw sections for
   --  the leading and trailing comments and extract them into these sections.
   --
   --  @param Decl_Node           Whole declaration.
   --  @param Advanced_Groups
   --    Advanced processing of the groups: empty line is added at the and
   --    of the section's text when it is not empty and processing of the
   --    group comment is started.
   --  @param Documentation       Structured comment to fill.

   procedure Extract_General_Trailing_Documentation
     (Decl_Node        : Basic_Decl'Class;
      Pattern          : VSS.Regular_Expressions.Regular_Expression;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Documentation    : in out Structured_Comment'Class;
      Trailing_Section : out not null Section_Access);
   --  Creates leading documetation section of the structured comment
   --  and extracts leading documentation follow general rules (there are
   --  few exceptions from this rules, like ordinary and generic package
   --  declarations).
   --
   --  @param Decl_Node        Declaration node
   --  @param Pattern
   --    Regular expression to check whenther line should be included into
   --    the documentation or not.
   --  @param Last_Section
   --    Last section inside the declaration. If there are some comments after
   --    the declaration and its indentation is equal of deeper than the value
   --    of the Minimum_Indent parameter, this section is filled by these
   --    comments.
   --  @param Minimum_Indent   Minimum indentation to fill last section.
   --  @param Documentation    Structured comment to add and fill section
   --  @param Trailing_Section Trailing raw text.

   procedure Extract_General_Leading_Trailing_Documentation
     (Decl_Node        : Basic_Decl'Class;
      Options          : GNATdoc.Comments.Options.Extractor_Options;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Documentation    : in out Structured_Comment'Class;
      Leading_Section  : out not null Section_Access;
      Trailing_Section : out not null Section_Access);
   --  Call both Extract_General_Leading_Documentation and
   --  Extract_General_Trailing_Documentation subprograms.

   procedure Extract_Leading_Section
     (Token_Start       : Token_Reference;
      Options           : GNATdoc.Comments.Options.Extractor_Options;
      Separator_Allowed : Boolean;
      Documentation     : in out Structured_Comment'Class;
      Section           : out not null Section_Access);
   --  Creates leading documetation section of the structured comment
   --  and extracts leading documentation.
   --
   --  @param Token_Start     Start token of the declaration node.
   --  @param Options         Extractor options
   --  @param Separator_Allowed
   --    Whether empty line is allowed between line that contains Token_Start
   --    and comment. It is the case for packages, tasks and protected
   --    objects.
   --  @param Documentation   Structured comment to add and fill section
   --  @param Section         Created section

   procedure Extract_Upper_Intermediate_Section
     (Token_Start   : Token_Reference;
      Token_End     : Token_Reference;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class;
      Section       : out Section_Access)
     with Pre => Kind (Data (Token_Start)) in Ada_Is | Ada_With;
   --  Extract documentation from the upper intermediate section: after
   --  Token_Start ('is' or 'with') and before any other declarations.

   procedure Fill_Code_Snippet
     (Node          : Ada_Node'Class;
      Documentation : in out Structured_Comment'Class);
   --  Extract code snippet of declaration, remove all comments from it,
   --  and create code snippet section of the structured comment.

   procedure Remove_Comment_Start_And_Indentation
     (Documentation : in out Structured_Comment'Class;
      Pattern       : VSS.Regular_Expressions.Regular_Expression);
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

   procedure Append_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression);
   --  Append given Line to the Text when Pattern is valid and Line match to
   --  Pattern. Always append Line when Pattern is invalid.

   procedure Prepend_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression);
   --  Prepend given Line to the Text when Pattern is valid and Line match to
   --  Pattern. Always prepend Line when Pattern is invalid.

   -------------------------------
   -- Append_Documentation_Line --
   -------------------------------

   procedure Append_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression)
   is
      L : constant Virtual_String := To_Virtual_String (Line);
      M : Regular_Expression_Match;

   begin
      if Pattern.Is_Valid then
         M := Pattern.Match (L);

         if M.Has_Match then
            Text.Append (L);
         end if;

      else
         Text.Append (L);
      end if;
   end Append_Documentation_Line;

   -------------
   -- Extract --
   -------------

   procedure Extract
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class) is
   begin
      case Node.Kind is
         when Ada_Package_Decl =>
            Extract_Base_Package_Decl_Documentation
              (Basic_Decl_Node        => Node.As_Package_Decl,
               Base_Package_Decl_Node => Node.As_Package_Decl,
               Options                => Options,
               Documentation          => Documentation);

         when Ada_Abstract_Subp_Decl | Ada_Subp_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node     => Node,
               Spec_Node     => Node.As_Classic_Subp_Decl.F_Subp_Spec,
               Expr_Node     => No_Expr,
               Aspects_Node  => Node.F_Aspects,
               Options       => Options,
               Documentation => Documentation);

         when Ada_Expr_Function =>
            Extract_Subprogram_Documentation
              (Decl_Node     => Node,
               Spec_Node     => Node.As_Base_Subp_Body.F_Subp_Spec,
               Expr_Node     => Node.As_Expr_Function.F_Expr,
               Aspects_Node  => Node.F_Aspects,
               Options       => Options,
               Documentation => Documentation);

         when Ada_Null_Subp_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node     => Node,
               Spec_Node     => Node.As_Base_Subp_Body.F_Subp_Spec,
               Expr_Node     => No_Expr,
               Aspects_Node  => Node.F_Aspects,
               Options       => Options,
               Documentation => Documentation);

         when Ada_Subp_Body =>
            Extract_Subprogram_Documentation
              (Decl_Node     => Node,
               Spec_Node     => Node.As_Base_Subp_Body.F_Subp_Spec,
               Expr_Node     => No_Expr,
               Aspects_Node  => No_Aspect_Spec,
               Options       => Options,
               Documentation => Documentation);

         when Ada_Generic_Package_Decl =>
            Extract_Generic_Package_Decl_Documentation
              (Node.As_Generic_Package_Decl, Options, Documentation);

         when Ada_Generic_Package_Instantiation =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Generic_Package_Instantiation, Options, Documentation);

         when Ada_Generic_Subp_Instantiation =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Generic_Subp_Instantiation, Options, Documentation);

         when Ada_Package_Renaming_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Package_Renaming_Decl, Options, Documentation);

         when Ada_Subp_Renaming_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node     => Node,
               Spec_Node     => Node.As_Subp_Renaming_Decl.F_Subp_Spec,
               Expr_Node     => No_Expr,
               Aspects_Node  => No_Aspect_Spec,
               Options       => Options,
               Documentation => Documentation);

         when Ada_Type_Decl =>
            case Node.As_Type_Decl.F_Type_Def.Kind is
               when Ada_Array_Type_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Enum_Type_Def =>
                  Extract_Enumeration_Type_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Derived_Type_Def =>
                  if Node.As_Type_Decl.F_Type_Def.As_Derived_Type_Def
                       .F_Record_Extension.Is_Null
                  then
                     Extract_Simple_Declaration_Documentation
                       (Node.As_Type_Decl, Options, Documentation);

                  else
                     Extract_Record_Type_Documentation
                       (Node.As_Type_Decl, Options, Documentation);
                  end if;

               when Ada_Interface_Type_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Mod_Int_Type_Def | Ada_Signed_Int_Type_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Record_Type_Def =>
                  Extract_Record_Type_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Private_Type_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Type_Access_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Access_To_Subp_Def =>
                  Extract_Subprogram_Documentation
                    (Decl_Node     => Node,
                     Spec_Node     =>
                        Node.As_Type_Decl.F_Type_Def
                          .As_Access_To_Subp_Def.F_Subp_Spec,
                     Expr_Node     => No_Expr,
                     Aspects_Node  => No_Aspect_Spec,
                     Options       => Options,
                     Documentation => Documentation);

               when others =>
                  raise Program_Error;
            end case;

         when Ada_Subtype_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Subtype_Decl, Options, Documentation);

         when Ada_Object_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Object_Decl, Options, Documentation);

         when Ada_Number_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Number_Decl, Options, Documentation);

         when Ada_Exception_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Exception_Decl, Options, Documentation);

         when Ada_Single_Task_Decl =>
            Extract_Single_Task_Decl_Documentation
              (Node.As_Single_Task_Decl,
               Node.As_Single_Task_Decl.F_Task_Type,
               Options,
               Documentation);

         when Ada_Task_Type_Decl =>
            Extract_Single_Task_Decl_Documentation
              (Node.As_Task_Type_Decl,
               Node.As_Task_Type_Decl,
               Options,
               Documentation);

         when Ada_Entry_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node     => Node,
               Spec_Node     => Node.As_Entry_Decl.F_Spec,
               Expr_Node     => No_Expr,
               Aspects_Node  => No_Aspect_Spec,
               Options       => Options,
               Documentation => Documentation);

         when others =>
            raise Program_Error;
      end case;
   end Extract;

   -------------
   -- Extract --
   -------------

   function Extract
     (Node    : Libadalang.Analysis.Basic_Decl'Class;
      Options : GNATdoc.Comments.Options.Extractor_Options)
      return not null Structured_Comment_Access is
   begin
      return Result : not null Structured_Comment_Access :=
        new Structured_Comment
      do
         Extract (Node, Options, Result.all);
      end return;
   end Extract;

   -------------
   -- Extract --
   -------------

   function Extract
     (Node    : Libadalang.Analysis.Basic_Decl'Class;
      Options : GNATdoc.Comments.Options.Extractor_Options)
      return Structured_Comment is
   begin
      return Result : Structured_Comment do
         Extract (Node, Options, Result);
      end return;
   end Extract;

   ---------------------------------------------
   -- Extract_Base_Package_Decl_Documentation --
   ---------------------------------------------

   procedure Extract_Base_Package_Decl_Documentation
     (Basic_Decl_Node        : Libadalang.Analysis.Basic_Decl'Class;
      Base_Package_Decl_Node : Libadalang.Analysis.Base_Package_Decl'Class;
      Options                : GNATdoc.Comments.Options.Extractor_Options;
      Documentation          : in out Structured_Comment'Class)
   is
      Prelude                    : Ada_Node_List;
      Header_Section             : Section_Access;
      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;
      Intermediate_Lower_Section : Section_Access;
      Last_Pragma_Or_Use         : Ada_Node;

   begin
      --  Header section: before context clauses of compilation unit

      if Basic_Decl_Node.P_Is_Compilation_Unit_Root then
         Prelude := Basic_Decl_Node.P_Enclosing_Compilation_Unit.F_Prelude;

         if Prelude.Sloc_Range.Start_Line = Prelude.Sloc_Range.End_Line
           and Prelude.Sloc_Range.Start_Column = Prelude.Sloc_Range.End_Column
         then
            Prelude := No_Ada_Node_List;
         end if;

         if not Prelude.Is_Null then
            Header_Section :=
              new Section'
                (Kind             => Raw,
                 Symbol           => "<<HEADER>>",
                 Name             => <>,
                 Text             => <>,
                 others           => <>);
            Documentation.Sections.Append (Header_Section);

            --  Going from the line before the first line of prelude to find
            --  an empty line and append all text till the next empty line to
            --  the header section.

            declare
               Token : Token_Reference := Prelude.Token_Start;
               Found : Boolean         := False;

            begin
               loop
                  Token := Previous (Token);

                  exit when Token = No_Token;

                  case Kind (Data (Token)) is
                     when Ada_Comment =>
                        if Found then
                           Prepend_Documentation_Line
                             (Header_Section.Text,
                              Text (Token),
                              Options.Pattern);
                        end if;

                     when Ada_Whitespace =>
                        declare
                           Location : constant Source_Location_Range :=
                             Sloc_Range (Data (Token));

                        begin
                           if Location.End_Line - Location.Start_Line > 1 then
                              exit when Found;

                              Found := True;
                           end if;
                        end;

                     when others =>
                        --  No tokens of other kinds are possible.

                        raise Program_Error;
                  end case;
               end loop;
            end;
         end if;
      end if;

      --  Leading section: before the package declaration and after context
      --  clauses of the compilation unit

      if not Basic_Decl_Node.P_Is_Compilation_Unit_Root or Prelude.Is_Null then
         Extract_Leading_Section
           (Basic_Decl_Node.Token_Start,
            Options,
            True,
            Documentation,
            Leading_Section);
      end if;

      --  Looukp last use clause or pragma declarations at the beginning of the
      --  public part of the package.

      for N of Base_Package_Decl_Node.F_Public_Part.F_Decls loop
         case N.Kind is
            when Ada_Pragma_Node | Ada_Use_Clause =>
               Last_Pragma_Or_Use := N.As_Ada_Node;

            when others =>
               exit;
         end case;
      end loop;

      --  Upper intermediate section: after 'is' and before any declarations.

      declare
         Token : Token_Reference := Base_Package_Decl_Node.Token_Start;

      begin
         --  Lookup 'is' in the package declaration

         loop
            Token := Next (Token);

            exit when
              Token = No_Token or else Kind (Data (Token)) = Ada_Is;
         end loop;

         Extract_Upper_Intermediate_Section
           (Token,
            Base_Package_Decl_Node.Token_End,
            Options,
            Documentation,
            Intermediate_Upper_Section);
      end;

      --  Lower intermediate section: after 'is' and before any declarations.

      if not Last_Pragma_Or_Use.Is_Null then
         Intermediate_Lower_Section :=
           new Section'
             (Kind             => Raw,
              Symbol           => "<<INTERMEDIATE UPPER>>",
              Name             => <>,
              Text             => <>,
              others           => <>);
         Documentation.Sections.Append (Intermediate_Lower_Section);

         declare
            Token : Token_Reference := Last_Pragma_Or_Use.Token_End;
            Found : Boolean := False;

         begin
            loop
               Token := Next (Token);

               exit when Token = No_Token;

               case Kind (Data (Token)) is
                  when Ada_Comment =>
                     Found := True;
                     Append_Documentation_Line
                       (Intermediate_Lower_Section.Text,
                        Text (Token),
                        Options.Pattern);

                  when Ada_Whitespace =>
                     declare
                        Location : constant Source_Location_Range :=
                          Sloc_Range (Data (Token));

                     begin
                        if Location.End_Line - Location.Start_Line > 1 then
                           exit when Found;

                           Found := True;
                        end if;
                     end;

                  when others =>
                     exit;
               end case;
            end loop;
         end;
      end if;

      Remove_Comment_Start_And_Indentation (Documentation, Options.Pattern);

      declare
         Raw_Section : Section_Access;

      begin
         --  Select most appropriate section.

         if not Intermediate_Upper_Section.Text.Is_Empty then
            Raw_Section := Intermediate_Upper_Section;

         elsif Intermediate_Lower_Section /= null
           and then not Intermediate_Lower_Section.Text.Is_Empty
         then
            Raw_Section := Intermediate_Lower_Section;

         elsif Leading_Section /= null
           and then not Leading_Section.Text.Is_Empty
         then
            Raw_Section := Leading_Section;

         elsif Header_Section /= null
           and then not Header_Section.Text.Is_Empty
         then
            Raw_Section := Header_Section;
         end if;

         Parse_Raw_Section
           (Raw_Section,
            (Private_Tag => True,
             Formal_Tag  => Basic_Decl_Node /= Base_Package_Decl_Node,
             others      => False),
            Documentation);
      end;
   end Extract_Base_Package_Decl_Documentation;

   --------------------------------------------
   -- Extract_Enumeration_Type_Documentation --
   --------------------------------------------

   procedure Extract_Enumeration_Type_Documentation
     (Node          : Libadalang.Analysis.Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      Enum_Node         : constant Enum_Type_Def'Class :=
        Node.F_Type_Def.As_Enum_Type_Def;
      Advanced_Groups   : Boolean;
      Last_Section      : Section_Access;
      Minimum_Indent    : Column_Number;
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;
      Component_Builder :
        GNATdoc.Comments.Builders.Enumerations.Enumeration_Components_Builder;

   begin
      Component_Builder.Build
        (Documentation'Unchecked_Access,
         Options,
         Enum_Node,
         Advanced_Groups,
         Last_Section,
         Minimum_Indent);

      Fill_Structured_Comment
        (Decl_Node       => Node,
         Advanced_Groups => Advanced_Groups,
         Pattern         => Options.Pattern,
         Documentation   => Documentation);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Documentation    => Documentation,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet (Node, Documentation);

      Remove_Comment_Start_And_Indentation (Documentation, Options.Pattern);

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
            Documentation);
      end;
   end Extract_Enumeration_Type_Documentation;

   ----------------------------------------------------
   -- Extract_General_Leading_Trailing_Documentation --
   ----------------------------------------------------

   procedure Extract_General_Leading_Trailing_Documentation
     (Decl_Node        : Basic_Decl'Class;
      Options          : GNATdoc.Comments.Options.Extractor_Options;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Documentation    : in out Structured_Comment'Class;
      Leading_Section  : out not null Section_Access;
      Trailing_Section : out not null Section_Access) is
   begin
      Extract_Leading_Section
        (Decl_Node.Token_Start,
         Options,
         False,
         Documentation,
         Leading_Section);
      Extract_General_Trailing_Documentation
        (Decl_Node,
         Options.Pattern,
         Last_Section,
         Minimum_Indent,
         Documentation,
         Trailing_Section);
   end Extract_General_Leading_Trailing_Documentation;

   --------------------------------------------
   -- Extract_General_Trailing_Documentation --
   --------------------------------------------

   procedure Extract_General_Trailing_Documentation
     (Decl_Node        : Basic_Decl'Class;
      Pattern          : VSS.Regular_Expressions.Regular_Expression;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Documentation    : in out Structured_Comment'Class;
      Trailing_Section : out not null Section_Access) is
   begin
      --  Create and add trailing section.

      Trailing_Section :=
        new Section'
          (Kind             => Raw,
           Symbol           => "<<TRAILING>>",
           Name             => <>,
           Text             => <>,
           others           => <>);
      Documentation.Sections.Append (Trailing_Section);

      --  Process tokens after the declaration node.

      declare
         Current_Node : Ada_Node := Decl_Node.As_Ada_Node;
         Next_Node    : Ada_Node;
         Token        : Token_Reference;
         In_Last      : Boolean := Last_Section /= null;

      begin
         --  Skip till the last sibling not separated from the given
         --  declaration node by the empty line. It is case of pragmas
         --  and representation clauses after declaration but before
         --  documentation comments.

         loop
            Next_Node := Current_Node.Next_Sibling;

            exit when
              Next_Node.Is_Null
                or else Current_Node.Sloc_Range.End_Line
                          /= Next_Node.Sloc_Range.Start_Line - 1;

            Current_Node := Next_Node;
         end loop;

         Token := Current_Node.Token_End;

         loop
            Token := Next (Token);

            exit when Token = No_Token;

            case Kind (Data (Token)) is
               when Ada_Comment =>
                  if In_Last then
                     if Sloc_Range (Data (Token)).Start_Column
                          >= Minimum_Indent
                     then
                        Append_Documentation_Line
                          (Last_Section.Text, Text (Token), Pattern);

                        goto Done;

                     else
                        In_Last := False;
                     end if;
                  end if;

                  Append_Documentation_Line
                    (Trailing_Section.Text, Text (Token), Pattern);

                  <<Done>>

               when Ada_Whitespace =>
                  declare
                     Location : constant Source_Location_Range :=
                       Sloc_Range (Data (Token));

                  begin
                     exit when Location.End_Line - Location.Start_Line > 1;
                  end;

               when others =>
                  exit;
            end case;
         end loop;
      end;
   end Extract_General_Trailing_Documentation;

   ------------------------------------------------
   -- Extract_Generic_Package_Decl_Documentation --
   ------------------------------------------------

   procedure Extract_Generic_Package_Decl_Documentation
     (Node          : Libadalang.Analysis.Generic_Package_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      Component_Builder :
        GNATdoc.Comments.Builders.Generics.Generic_Components_Builder;

   begin
      Component_Builder.Build
        (Documentation'Unchecked_Access,
         Options,
         Node.F_Formal_Part,
         Node.F_Package_Decl);

      Fill_Structured_Comment
        (Decl_Node       => Node,
         Advanced_Groups => False,
         Pattern         => Options.Pattern,
         Documentation   => Documentation);

      --  Fill_Code_Snippet (Node, Documentation);

      Extract_Base_Package_Decl_Documentation
        (Node, Node.F_Package_Decl, Options, Documentation);
   end Extract_Generic_Package_Decl_Documentation;

   -----------------------------
   -- Extract_Leading_Section --
   -----------------------------

   procedure Extract_Leading_Section
     (Token_Start       : Token_Reference;
      Options           : GNATdoc.Comments.Options.Extractor_Options;
      Separator_Allowed : Boolean;
      Documentation     : in out Structured_Comment'Class;
      Section           : out not null Section_Access) is
   begin
      --  Create and add leading section

      Section :=
        new GNATdoc.Comments.Section'
          (Kind             => Raw,
           Symbol           => "<<LEADING>>",
           Name             => <>,
           Text             => <>,
           others           => <>);
      Documentation.Sections.Append (Section);

      --  Process tokens before the start token.

      declare
         Token : Token_Reference := Token_Start;
         Found : Boolean         := False;
         --  Separated : Boolean := False;

      begin
         loop
            Token := Previous (Token);

            exit when Token = No_Token;

            case Kind (Data (Token)) is
               when Ada_Comment =>
                  Found := True;
                  Prepend_Documentation_Line
                    (Section.Text, Text (Token), Options.Pattern);

               when Ada_Whitespace =>
                  declare
                     Location : constant Source_Location_Range :=
                       Sloc_Range (Data (Token));

                  begin
                     if Location.End_Line - Location.Start_Line > 1 then
                        if not Separator_Allowed then
                           exit;

                        else
                           exit when Found;

                           Found := True;
                        end if;
                     end if;
                  end;

               when others =>
                  --  Leading section must be separated from the context
                  --  clauses by the empty line, thus any other tokens
                  --  cleanup accumulated text.

                  if Separator_Allowed then
                     Section.Text.Clear;
                  end if;

                  exit;
            end case;
         end loop;
      end;
   end Extract_Leading_Section;

   ---------------------------------------
   -- Extract_Record_Type_Documentation --
   ---------------------------------------

   procedure Extract_Record_Type_Documentation
     (Node          : Libadalang.Analysis.Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      Advanced_Groups   : Boolean;
      Last_Section      : Section_Access;
      Minimum_Indent    : Column_Number;
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;
      Component_Builder :
        GNATdoc.Comments.Builders.Records.Record_Components_Builder;

   begin
      Component_Builder.Build
        (Documentation'Unchecked_Access,
         Options,
         Node,
         Advanced_Groups,
         Last_Section,
         Minimum_Indent);

      Fill_Structured_Comment
        (Decl_Node       => Node,
         Advanced_Groups => Advanced_Groups,
         Pattern         => Options.Pattern,
         Documentation   => Documentation);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Documentation    => Documentation,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet (Node, Documentation);

      Remove_Comment_Start_And_Indentation (Documentation, Options.Pattern);

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
            (Member_Tag => True, others => False),
            Documentation);
      end;
   end Extract_Record_Type_Documentation;

   ----------------------------------------------
   -- Extract_Simple_Declaration_Documentation --
   ----------------------------------------------

   procedure Extract_Simple_Declaration_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;

   begin
      Fill_Structured_Comment
        (Decl_Node       => Node,
         Advanced_Groups => False,
         Pattern         => Options.Pattern,
         Documentation   => Documentation);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => null,
         Minimum_Indent   => 0,
         Documentation    => Documentation,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet (Node, Documentation);

      Remove_Comment_Start_And_Indentation (Documentation, Options.Pattern);

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

         Parse_Raw_Section (Raw_Section, (others => False), Documentation);
      end;
   end Extract_Simple_Declaration_Documentation;

   --------------------------------------------
   -- Extract_Single_Task_Decl_Documentation --
   --------------------------------------------

   procedure Extract_Single_Task_Decl_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Decl          : Libadalang.Analysis.Task_Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class)
   is
      Definition       : Libadalang.Analysis.Task_Def'Class :=
        Decl.F_Definition;
      Is_Or_With_Token : Token_Reference;

      Leading_Section            : Section_Access;
      Trailing_Section           : Section_Access;
      Intermediate_Upper_Section : Section_Access;

   begin
      Extract_Leading_Section
        (Node.Token_Start, Options, True, Documentation, Leading_Section);

      if Definition.Is_Null then
         --  It is the case of the entry-less and definition-less task
         --  declaration. Documentation may be provided by the comment
         --  immidiately below task declaration. Retreive it into the
         --  tailing section.

         Extract_General_Trailing_Documentation
           (Node, Options.Pattern, null, 0, Documentation, Trailing_Section);

      else
         --  Overwise, documentation may be provided inside task definition
         --  before the first entry.

         --  Lookup for 'is' token that begins task definition, or 'with'
         --  token that ends interface part.

         Is_Or_With_Token := Definition.Token_Start;

         if Definition.F_Interfaces.Children_Count /= 0 then
            Is_Or_With_Token := Definition.F_Interfaces.Token_End;

            loop
               Is_Or_With_Token := Next (Is_Or_With_Token);

               exit when Is_Or_With_Token = No_Token;

               case Kind (Data (Is_Or_With_Token)) is
                  when Ada_Whitespace =>
                     null;

                  when Ada_With =>
                     exit;

                  when others =>
                     raise Program_Error;
               end case;
            end loop;
         end if;

         Extract_Upper_Intermediate_Section
           (Is_Or_With_Token,
            Definition.Token_End,
            Options,
            Documentation,
            Intermediate_Upper_Section);
      end if;

      Remove_Comment_Start_And_Indentation (Documentation, Options.Pattern);

      declare
         Raw_Section : Section_Access;

      begin
         --  Select most appropriate section.

         if Trailing_Section /= null
           and then not Trailing_Section.Text.Is_Empty
         then
            --  Trailing section is present in the corner case only, and
            --  preferable section in this case.

            Raw_Section := Trailing_Section;

         elsif Intermediate_Upper_Section /= null
           and then not Intermediate_Upper_Section.Text.Is_Empty
         then
            Raw_Section := Intermediate_Upper_Section;

         elsif not Leading_Section.Text.Is_Empty then
            Raw_Section := Leading_Section;
         end if;

         Parse_Raw_Section
           (Raw_Section,
            (Private_Tag => True,
             Member_Tag  => True,
             others      => False),
            Documentation);
      end;
   end Extract_Single_Task_Decl_Documentation;

   --------------------------------------
   -- Extract_Subprogram_Documentation --
   --------------------------------------

   procedure Extract_Subprogram_Documentation
     (Decl_Node      : Libadalang.Analysis.Basic_Decl'Class;
      Spec_Node      : Libadalang.Analysis.Base_Subp_Spec'Class;
      Expr_Node      : Expr'Class;
      Aspects_Node   : Aspect_Spec'Class;
      Options        : GNATdoc.Comments.Options.Extractor_Options;
      Documentation  : out Structured_Comment'Class)
   is

      --------------------------------
      -- Intermediate_Section_Range --
      --------------------------------

      procedure Intermediate_Section_Range
        (Spec_Node        : Base_Subp_Spec'Class;
         Name_Node        : Defining_Name'Class;
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
        (Spec_Node        : Base_Subp_Spec'Class;
         Name_Node        : Defining_Name'Class;
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

         elsif not Name_Node.Is_Null then
            --  For parameterless procedures, intermadiate section starts
            --  after the procedure's name identifier.

            Upper_Start_Line := Name_Node.Sloc_Range.Start_Line;

         else
            --  For access to subprogram, intermediate section starts after
            --  the beginning of declaration.

            Upper_Start_Line := Spec_Node.Sloc_Range.Start_Line + 1;
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

      Name_Node                  : constant Defining_Name :=
        (case Spec_Node.Kind is
            when Ada_Subp_Spec  => Spec_Node.As_Subp_Spec.F_Subp_Name,
            when Ada_Entry_Spec => Spec_Node.As_Entry_Spec.F_Entry_Name,
            when others         => raise Program_Error);
      Params_Node                : constant Params'Class :=
        (case Spec_Node.Kind is
            when Ada_Subp_Spec  => Spec_Node.As_Subp_Spec.F_Subp_Params,
            when Ada_Entry_Spec => Spec_Node.As_Entry_Spec.F_Entry_Params,
            when others         => raise Program_Error);
      Returns_Node               : constant Type_Expr'Class :=
        (case Spec_Node.Kind is
            when Ada_Subp_Spec  => Spec_Node.As_Subp_Spec.F_Subp_Returns,
            when Ada_Entry_Spec => No_Type_Expr,
            when others         => raise Program_Error);

      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;
      Intermediate_Lower_Section : Section_Access;
      Trailing_Section           : Section_Access;
      Advanced_Groups            : Boolean;
      Last_Section               : Section_Access;
      Minimum_Indent             : Column_Number;
      Components_Builder         :
        GNATdoc.Comments.Builders.Subprograms.Subprogram_Components_Builder;

   begin
      --  Create "raw" section to collect all documentation for subprogram,
      --  exact range is used to fill comments after the end of the
      --  subprogram specification and before the name of the first aspect
      --  association, thus, location of the "when" keyword is not
      --  significant.

      Intermediate_Upper_Section :=
        new Section'
          (Kind   => Raw,
           Symbol => "<<INTERMEDIATE UPPER>>",
           Name   => <>,
           Text   => <>,
           others => <>);
      Intermediate_Lower_Section :=
        new Section'
          (Kind   => Raw,
           Symbol => "<<INTERMEDIATE LOWER>>",
           Name   => <>,
           Text   => <>,
           others => <>);
      Intermediate_Section_Range
        (Spec_Node,
         Name_Node,
         Params_Node,
         Returns_Node,
         Expr_Node,
         Aspects_Node,
         Intermediate_Upper_Section.Exact_Start_Line,
         Intermediate_Upper_Section.Exact_End_Line,
         Intermediate_Lower_Section.Exact_Start_Line,
         Intermediate_Lower_Section.Exact_End_Line);
      Documentation.Sections.Append (Intermediate_Upper_Section);
      Documentation.Sections.Append (Intermediate_Lower_Section);

      --  Create sections for parameters and return value.

      Components_Builder.Build
        (Documentation'Unchecked_Access,
         Options,
         Spec_Node,
         Name_Node,
         Params_Node,
         Returns_Node,
         Advanced_Groups,
         Last_Section,
         Minimum_Indent);

      --  Parse comments inside the subprogram declaration and fill
      --  text of raw, parameters and returns sections.

      Fill_Structured_Comment
        (Decl_Node       => Decl_Node,
         Pattern         => Options.Pattern,
         Advanced_Groups => Advanced_Groups,
         Documentation   => Documentation);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Decl_Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Documentation    => Documentation,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      --  Extract code snippet of declaration and remove all comments from
      --  it.

      Fill_Code_Snippet
        ((if Decl_Node.Kind in Ada_Type_Decl  --  Access to subprogram type
            then Decl_Node
            else Spec_Node),
         Documentation);

      --  Postprocess extracted text, for each group of lines, separated
      --  by empty line by remove of two minus signs and common leading
      --  whitespaces

      Remove_Comment_Start_And_Indentation (Documentation, Options.Pattern);

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
            Documentation);
      end;
   end Extract_Subprogram_Documentation;

   ----------------------------------------
   -- Extract_Upper_Intermediate_Section --
   ----------------------------------------

   procedure Extract_Upper_Intermediate_Section
     (Token_Start   : Token_Reference;
      Token_End     : Token_Reference;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class;
      Section       : out Section_Access)
   is
      Token     : Token_Reference := Token_Start;
      Found     : Boolean := False;
      Separated : Boolean := False;
      --  Whether comment block is separated from the list with 'is' keyword
      --  by empty line. In this case comment block can belong to the entity
      --  declaration below.

   begin
      Section :=
        new GNATdoc.Comments.Section'
          (Kind             => Raw,
           Symbol           => "<<INTERMEDIATE UPPER>>",
           Name             => <>,
           Text             => <>,
           others           => <>);
      Documentation.Sections.Append (Section);

      loop
         Token := Next (Token);

         exit when Token = No_Token or else Token = Token_End;

         case Kind (Data (Token)) is
            when Ada_Comment =>
               Found := True;
               Append_Documentation_Line
                 (Section.Text, Text (Token), Options.Pattern);

            when Ada_Whitespace =>
               declare
                  Location : constant Source_Location_Range :=
                    Sloc_Range (Data (Token));

               begin
                  if Location.End_Line - Location.Start_Line > 1 then
                     exit when Found;

                     Found     := True;
                     Separated := True;
                  end if;
               end;

            when others =>
               if Separated then
                  --  Comment block is separated from the line with 'is'
                  --  keyword by an empty line, but not separated from the
                  --  entity declaration below, thus don't include it into
                  --  package documentation.

                  Section.Text.Clear;
               end if;

               exit;
         end case;
      end loop;
   end Extract_Upper_Intermediate_Section;

   -----------------------
   -- Fill_Code_Snippet --
   -----------------------

   procedure Fill_Code_Snippet
     (Node          : Ada_Node'Class;
      Documentation : in out Structured_Comment'Class)
   is

      procedure Remove_Leading_Spaces
        (Text       : in out VSS.String_Vectors.Virtual_String_Vector;
         Line_Index : Positive;
         Amount     : VSS.Strings.Character_Count);
      --  Remove given amount of space characters from the line of the given
      --  index.

      ---------------------------
      -- Remove_Leading_Spaces --
      ---------------------------

      procedure Remove_Leading_Spaces
        (Text       : in out VSS.String_Vectors.Virtual_String_Vector;
         Line_Index : Positive;
         Amount     : VSS.Strings.Character_Count)
      is
         Line      : Virtual_String     := Text (Line_Index);
         Iterator  : Character_Iterator := Line.At_First_Character;
         Count     : Character_Count    := Amount;

      begin
         while Iterator.Forward loop
            exit when Iterator.Element /= Space;

            Count := Count - 1;

            if Count = 0 then
               Text.Replace (Line_Index, Line.Tail_From (Iterator));

               exit;
            end if;
         end loop;
      end Remove_Leading_Spaces;

      Node_Location   : constant Source_Location_Range := Node.Sloc_Range;
      Snippet_Section : Section_Access;
      Text            : Virtual_String_Vector;

   begin
      Text :=
        To_Virtual_String (Node.Text).Split_Lines (Ada_New_Line_Function);

      --  Indent first line correctly.

      declare
         Line : Virtual_String := Text (1);

      begin
         for J in 2 .. Node_Location.Start_Column loop
            Line.Prepend (' ');
         end loop;

         Text.Replace (1, Line);
      end;

      --  Remove comments

      declare
         Line_Offset : constant Line_Number := Node_Location.Start_Line - 1;
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

         --  Remove all empty lines

         for Index in reverse 1 .. Text.Length loop
            if Text (Index).Is_Empty then
               Text.Delete (Index);
            end if;
         end loop;
      end;

      --  For the subprogram specification check whether "overriding"/"not
      --  overriding" indicator is used at the same line with subprogram
      --  specification and reformat code snippet: first line of the
      --  subprogram specification is moved left to position of the indicator;
      --  if subprogram parameter is present on this line too, all lines
      --  below is moved too, unless any non-space characters are found in
      --  the removed slice of the line.

      if Node.Kind = Ada_Subp_Spec
        and then Node.Parent.Kind
                   in Ada_Classic_Subp_Decl | Ada_Base_Subp_Body
      then
         declare
            Indicator_Node     : constant Overriding_Node :=
              (if Node.Parent.Kind in Ada_Classic_Subp_Decl
               then Node.Parent.As_Classic_Subp_Decl.F_Overriding
               else Node.Parent.As_Base_Subp_Body.F_Overriding);
            Indicator_Location : constant Source_Location_Range :=
              Indicator_Node.Sloc_Range;
            Offset             : VSS.Strings.Character_Count := 0;

         begin
            if Indicator_Node.Kind /= Ada_Overriding_Unspecified
              and then Node_Location.Start_Line = Indicator_Location.Start_Line
            then
               Offset :=
                 VSS.Strings.Character_Count
                   (Node_Location.Start_Column
                      - Indicator_Location.Start_Column);
            end if;

            if Offset /= 0 then
               Remove_Leading_Spaces (Text, 1, Offset);

               declare
                  Params_Node : constant Params :=
                    Node.As_Subp_Spec.F_Subp_Params;
                  P1_Node     : Ada_Node;
                  Success     : Boolean;

               begin
                  if Params_Node /= No_Params then
                     Params_Node.F_Params.Get_Child (1, Success, P1_Node);

                     if Success
                       and then P1_Node.Sloc_Range.Start_Line
                                  = Node_Location.Start_Line
                     then
                        for J in 2 .. Text.Length loop
                           Remove_Leading_Spaces (Text, J, Offset);
                        end loop;
                     end if;
                  end if;
               end;
            end if;
         end;
      end if;

      Snippet_Section :=
        new Section'
          (Kind => Snippet, Symbol => "ada", Text => Text, others => <>);
      Documentation.Sections.Append (Snippet_Section);
   end Fill_Code_Snippet;

   -----------------------------
   -- Fill_Structured_Comment --
   -----------------------------

   procedure Fill_Structured_Comment
     (Decl_Node       : Basic_Decl'Class;
      Advanced_Groups : Boolean;
      Pattern         : VSS.Regular_Expressions.Regular_Expression;
      Documentation   : in out Structured_Comment'Class)
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
                     if Advanced_Groups
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
           & "@(param|return|exception|enum|field|formal|private)"
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

            elsif Match.Captured (1) = "field" then
               Tag  := Member_Tag;
               Kind := Field;

            elsif Match.Captured (1) = "formal" then
               Tag  := Formal_Tag;
               Kind := Field;

            elsif Match.Captured (1) = "private" then
               Tag  := Private_Tag;

            else
               raise Program_Error;
            end if;

            if not Allowed_Tags (Tag) then
               goto Default;
            end if;

            Line_Tail := Line.Tail_After (Match.Last_Marker);

            if Tag = Private_Tag then
               Documentation.Is_Private := True;

               goto Skip;

            elsif Kind
                 in Parameter | Raised_Exception | Enumeration_Literal | Field
            then
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

            <<Skip>>

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

   --------------------------------
   -- Prepend_Documentation_Line --
   --------------------------------

   procedure Prepend_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression)
   is
      L : constant Virtual_String := To_Virtual_String (Line);
      M : Regular_Expression_Match;

   begin
      if Pattern.Is_Valid then
         M := Pattern.Match (L);

         if M.Has_Match then
            Text.Prepend (L);
         end if;

      else
         Text.Prepend (L);
      end if;
   end Prepend_Documentation_Line;

   ------------------------------------------
   -- Remove_Comment_Start_And_Indentation --
   ------------------------------------------

   procedure Remove_Comment_Start_And_Indentation
     (Documentation : in out Structured_Comment'Class;
      Pattern       : VSS.Regular_Expressions.Regular_Expression) is
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
                        --  Skip '--' or documentation pattern from all
                        --  sections, but snippet.

                        if not Pattern.Is_Valid then
                           Success := Iterator.Forward;
                           pragma Assert
                             (Success and then Iterator.Element = '-');

                           Success := Iterator.Forward;
                           pragma Assert
                             (Success and then Iterator.Element = '-');

                        else
                           declare
                              Match : Regular_Expression_Match :=
                                Pattern.Match (Line);

                           begin
                              Iterator.Set_At (Match.Last_Marker);
                           end;
                        end if;
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
