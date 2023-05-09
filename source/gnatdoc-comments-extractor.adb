------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2023, AdaCore                     --
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
with VSS.Characters.Latin;            use VSS.Characters.Latin;
with VSS.Regular_Expressions;         use VSS.Regular_Expressions;
with VSS.String_Vectors;              use VSS.String_Vectors;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Character_Iterators; use VSS.Strings.Character_Iterators;

with GNATdoc.Comments.Builders.Private_Types;
with GNATdoc.Comments.Builders.Enumerations;
with GNATdoc.Comments.Builders.Generics;
with GNATdoc.Comments.Builders.Protecteds;
with GNATdoc.Comments.Builders.Records;
with GNATdoc.Comments.Builders.Subprograms;
with GNATdoc.Comments.Utilities;      use GNATdoc.Comments.Utilities;

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

   procedure Extract_Generic_Decl_Documentation
     (Node          : Libadalang.Analysis.Generic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class);

   procedure Extract_Subprogram_Documentation
     (Decl_Node    : Libadalang.Analysis.Basic_Decl'Class;
      Spec_Node    : Libadalang.Analysis.Base_Subp_Spec'Class;
      Expr_Node    : Expr'Class;
      Aspects_Node : Aspect_Spec'Class;
      Options      : GNATdoc.Comments.Options.Extractor_Options;
      Sections     : in out Section_Vectors.Vector)
     with Pre =>
       Spec_Node.Kind in Ada_Subp_Spec | Ada_Entry_Spec;
   --  Extracts subprogram's documentation.
   --
   --  @param Decl_Node       Whole declaration
   --  @param Subp_Spec_Node  Subprogram specification
   --  @param Expr_Node       Expression of expression function
   --  @param Aspects_Node    List of aspects
   --  @param Options         Documentataion extraction options
   --  @param Documentation   Structured comment to fill

   procedure Extract_Entry_Body_Documentation
     (Decl_Node     : Libadalang.Analysis.Entry_Body'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class);
   --  Extracts entry body documentation.
   --
   --  @param Decl_Node      Whole declaration
   --  @param Options        Documentataion extraction options
   --  @param Documentation  Structured comment to fill

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

   procedure Extract_Private_Type_Documentation
     (Node     : Libadalang.Analysis.Basic_Decl'Class;
      Decl     : Libadalang.Analysis.Type_Decl'Class;
      Options  : GNATdoc.Comments.Options.Extractor_Options;
      Sections : in out Section_Vectors.Vector)
     with Pre =>
       (Decl.Kind in Ada_Type_Decl
          and then Decl.As_Type_Decl.F_Type_Def.Kind = Ada_Private_Type_Def)
       or else (Decl.Kind in Ada_Formal_Type_Decl
                  and then Decl.As_Formal_Type_Decl.F_Type_Def.Kind
                             = Ada_Private_Type_Def);
   --  Extract documentation for private type declaration.

   procedure Extract_Simple_Declaration_Documentation
     (Node     : Libadalang.Analysis.Basic_Decl'Class;
      Options  : GNATdoc.Comments.Options.Extractor_Options;
      Sections : in out Section_Vectors.Vector)
     with Pre => Node.Kind in Ada_Exception_Decl
                   | Ada_Generic_Formal_Package
                   | Ada_Generic_Package_Instantiation
                   | Ada_Generic_Subp_Instantiation
                   | Ada_Number_Decl
                   | Ada_Object_Decl
                   | Ada_Package_Renaming_Decl
                   | Ada_Subtype_Decl
     or (Node.Kind in Ada_Type_Decl
         and then Node.As_Type_Decl.F_Type_Def.Kind in Ada_Array_Type_Def
                    | Ada_Decimal_Fixed_Point_Def
                    | Ada_Floating_Point_Def
                    | Ada_Interface_Type_Def
                    | Ada_Mod_Int_Type_Def
                    | Ada_Ordinary_Fixed_Point_Def
                    | Ada_Signed_Int_Type_Def
                    | Ada_Type_Access_Def)
     or (Node.Kind in Ada_Type_Decl
         and then Node.As_Type_Decl.F_Type_Def.Kind = Ada_Derived_Type_Def
         and then Node.As_Type_Decl.F_Type_Def.As_Derived_Type_Def
                    .F_Record_Extension.Is_Null)
     or (Node.Kind in Ada_Generic_Formal_Type_Decl
         and then Node.As_Generic_Formal_Type_Decl.F_Decl.Kind
           = Ada_Incomplete_Formal_Type_Decl)
     or (Node.Kind in Ada_Generic_Formal_Type_Decl
         and then Node.As_Generic_Formal_Type_Decl.F_Decl.Kind
           = Ada_Formal_Type_Decl
         and then Node.As_Generic_Formal_Type_Decl.F_Decl.As_Formal_Type_Decl
                    .F_Type_Def.Kind in Ada_Type_Access_Def
                      | Ada_Array_Type_Def
                      | Ada_Decimal_Fixed_Point_Def
                      | Ada_Derived_Type_Def
                      | Ada_Floating_Point_Def
                      | Ada_Formal_Discrete_Type_Def
                      | Ada_Interface_Type_Def
                      | Ada_Ordinary_Fixed_Point_Def
                      | Ada_Mod_Int_Type_Def
                      | Ada_Signed_Int_Type_Def)
     or Node.Kind = Ada_Generic_Formal_Obj_Decl;
   --  Extract documentation for simple declaration (declarations that doesn't
   --  contains components).

   procedure Extract_Single_Task_Decl_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Decl          : Libadalang.Analysis.Task_Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class);
   --  Extract documentation for single task declaration.

   procedure Extract_Protected_Decl_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Definition    : Libadalang.Analysis.Protected_Def'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class);
   --  Extract documentation for protected type declaration.

   procedure Extract_Protected_Body_Documentation
     (Node          : Libadalang.Analysis.Protected_Body'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class);
   --  Extract documentation for protected body.

   procedure Extract_General_Trailing_Documentation
     (Decl_Node        : Basic_Decl'Class;
      Pattern          : VSS.Regular_Expressions.Regular_Expression;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Sections         : in out Section_Vectors.Vector;
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
   --  @param Sections         List of sections to add new section
   --  @param Trailing_Section Trailing raw text.

   procedure Extract_General_Leading_Trailing_Documentation
     (Decl_Node        : Basic_Decl'Class;
      Options          : GNATdoc.Comments.Options.Extractor_Options;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;
      Sections         : in out Section_Vectors.Vector;
      Leading_Section  : out not null Section_Access;
      Trailing_Section : out not null Section_Access);
   --  Call both Extract_General_Leading_Documentation and
   --  Extract_General_Trailing_Documentation subprograms.

   procedure Extract_Leading_Section
     (Token_Start       : Token_Reference;
      Options           : GNATdoc.Comments.Options.Extractor_Options;
      Separator_Allowed : Boolean;
      Sections          : in out Section_Vectors.Vector;
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
   --  @param Sections        List of sections to add new section
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
     (Node        : Ada_Node'Class;
      First_Token : Token_Reference;
      Last_Token  : Token_Reference;
      Sections    : in out Section_Vectors.Vector);
   --  Extract code snippet between given tokens, remove all comments from it,
   --  and create code snippet section of the structured comment.
   --
   --  @param Node         Declaration or specification node
   --  @param First_Token  First token of the range to be processed
   --  @param Last_Token   Last token of the range to be processed
   --  @param Sections     List of sections to append new section.

   procedure Remove_Comment_Start_And_Indentation
     (Sections : in out Section_Vectors.Vector;
      Pattern  : VSS.Regular_Expressions.Regular_Expression);
   --  Postprocess extracted text, for each group of lines, separated by empty
   --  line, by remove of two minus signs and common leading whitespaces. For
   --  code snippet remove common leading whitespaces only.
   --
   --  @param Sections  List of sections of the documentation
   --  @param Pattern   Regular expression to remove "start of comment" text

   procedure Parse_Raw_Section
     (Raw_Section   : Section_Access;
      Allowed_Tags  : Section_Tag_Flags;
      Sections      : in out Section_Vectors.Vector;
      Is_Private    : in out Boolean);
   --  Process raw documentation, fill sections and create description section.
   --
   --  @param Raw_Section    Raw section to process
   --  @param Allowed_Tags   Set of section tags to be processed
   --  @param Sections       Sections of the structured comment
   --  @param Is_Private     Set to True when private tag found

   procedure Parse_Raw_Section
     (Raw_Section   : Section_Access;
      Allowed_Tags  : Section_Tag_Flags;
      Sections      : in out Section_Vectors.Vector)
     with Pre => not Allowed_Tags (Private_Tag);
   --  Wrapper around Parse_Raw_Section when private tag is not allowed

   function Is_Ada_Separator (Item : Virtual_Character) return Boolean;
   --  Return True when given character is Ada's separator.
   --
   --  @param Item Character to be classified
   --  @return Whether given character is Ada's separator or not

   procedure Prepend_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression);
   --  Prepend given Line to the Text when Pattern is valid and Line match to
   --  Pattern. Always prepend Line when Pattern is invalid.

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
              (Decl_Node    => Node,
               Spec_Node    => Node.As_Classic_Subp_Decl.F_Subp_Spec,
               Expr_Node    => No_Expr,
               Aspects_Node => Node.F_Aspects,
               Options      => Options,
               Sections     => Documentation.Sections);

         when Ada_Expr_Function =>
            Extract_Subprogram_Documentation
              (Decl_Node    => Node,
               Spec_Node    => Node.As_Base_Subp_Body.F_Subp_Spec,
               Expr_Node    => Node.As_Expr_Function.F_Expr,
               Aspects_Node => Node.F_Aspects,
               Options      => Options,
               Sections     => Documentation.Sections);

         when Ada_Null_Subp_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node    => Node,
               Spec_Node    => Node.As_Base_Subp_Body.F_Subp_Spec,
               Expr_Node    => No_Expr,
               Aspects_Node => Node.F_Aspects,
               Options      => Options,
               Sections => Documentation.Sections);

         when Ada_Subp_Body =>
            Extract_Subprogram_Documentation
              (Decl_Node    => Node,
               Spec_Node    => Node.As_Base_Subp_Body.F_Subp_Spec,
               Expr_Node    => No_Expr,
               Aspects_Node => Node.As_Subp_Body.F_Aspects,
               Options      => Options,
               Sections     => Documentation.Sections);

         when Ada_Generic_Package_Decl | Ada_Generic_Subp_Decl =>
            Extract_Generic_Decl_Documentation
              (Node.As_Generic_Decl, Options, Documentation);

         --  when Ada_Generic_Subp_Decl =>
         --     Extract_Generic_Decl_Documentation
         --       (Node.As_Generic_Subp_Decl, Options, Documentation);

         when Ada_Generic_Package_Instantiation =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Generic_Package_Instantiation,
               Options,
               Documentation.Sections);

         when Ada_Generic_Subp_Instantiation =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Generic_Subp_Instantiation,
               Options,
               Documentation.Sections);

         when Ada_Package_Renaming_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Package_Renaming_Decl,
               Options,
               Documentation.Sections);

         when Ada_Subp_Renaming_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node    => Node,
               Spec_Node    => Node.As_Subp_Renaming_Decl.F_Subp_Spec,
               Expr_Node    => No_Expr,
               Aspects_Node => No_Aspect_Spec,
               Options      => Options,
               Sections     => Documentation.Sections);

         when Ada_Type_Decl =>
            --  Print (Node);
            case Node.As_Type_Decl.F_Type_Def.Kind is
               when Ada_Array_Type_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation.Sections);

               when Ada_Enum_Type_Def =>
                  Extract_Enumeration_Type_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Derived_Type_Def =>
                  if Node.As_Type_Decl.F_Type_Def.As_Derived_Type_Def
                       .F_Record_Extension.Is_Null
                  then
                     Extract_Simple_Declaration_Documentation
                       (Node.As_Type_Decl, Options, Documentation.Sections);

                  else
                     Extract_Record_Type_Documentation
                       (Node.As_Type_Decl, Options, Documentation);
                  end if;

               when Ada_Interface_Type_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation.Sections);

               when Ada_Decimal_Fixed_Point_Def
                  | Ada_Floating_Point_Def
                  | Ada_Mod_Int_Type_Def
                  | Ada_Ordinary_Fixed_Point_Def
                  | Ada_Signed_Int_Type_Def
               =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation.Sections);

               when Ada_Record_Type_Def =>
                  Extract_Record_Type_Documentation
                    (Node.As_Type_Decl, Options, Documentation);

               when Ada_Private_Type_Def =>
                  Extract_Private_Type_Documentation
                    (Node, Node.As_Type_Decl, Options, Documentation.Sections);

               when Ada_Type_Access_Def =>
                  Extract_Simple_Declaration_Documentation
                    (Node.As_Type_Decl, Options, Documentation.Sections);

               when Ada_Access_To_Subp_Def =>
                  Extract_Subprogram_Documentation
                    (Decl_Node    => Node,
                     Spec_Node    =>
                        Node.As_Type_Decl.F_Type_Def
                          .As_Access_To_Subp_Def.F_Subp_Spec,
                     Expr_Node    => No_Expr,
                     Aspects_Node => No_Aspect_Spec,
                     Options      => Options,
                     Sections     => Documentation.Sections);

               when others =>
                  raise Program_Error;
            end case;

         when Ada_Subtype_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Subtype_Decl, Options, Documentation.Sections);

         when Ada_Object_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Object_Decl, Options, Documentation.Sections);

         when Ada_Number_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Number_Decl, Options, Documentation.Sections);

         when Ada_Exception_Decl =>
            Extract_Simple_Declaration_Documentation
              (Node.As_Exception_Decl, Options, Documentation.Sections);

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

         when Ada_Single_Protected_Decl =>
            Extract_Protected_Decl_Documentation
              (Node.As_Single_Protected_Decl,
               Node.As_Single_Protected_Decl.F_Definition,
               Options,
               Documentation);

         when Ada_Protected_Type_Decl =>
            Extract_Protected_Decl_Documentation
              (Node.As_Protected_Type_Decl,
               Node.As_Protected_Type_Decl.F_Definition,
               Options,
               Documentation);

         when Ada_Protected_Body =>
            Extract_Protected_Body_Documentation
              (Node.As_Protected_Body, Options, Documentation);

         when Ada_Entry_Decl =>
            Extract_Subprogram_Documentation
              (Decl_Node    => Node,
               Spec_Node    => Node.As_Entry_Decl.F_Spec,
               Expr_Node    => No_Expr,
               Aspects_Node => No_Aspect_Spec,
               Options      => Options,
               Sections     => Documentation.Sections);

         when Ada_Entry_Body =>
            Extract_Entry_Body_Documentation
              (Decl_Node     => Node.As_Entry_Body,
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
      return Result : constant not null Structured_Comment_Access :=
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
            Documentation.Sections,
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

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

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
             Formal_Tag  => Basic_Decl_Node.Kind in Ada_Generic_Decl,
             others      => False),
            Documentation.Sections,
            Documentation.Is_Private);
      end;
   end Extract_Base_Package_Decl_Documentation;

   --------------------------------------
   -- Extract_Entry_Body_Documentation --
   --------------------------------------

   procedure Extract_Entry_Body_Documentation
     (Decl_Node     : Libadalang.Analysis.Entry_Body'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      --  entry Name
      --    (for Index use Index_Type)
      --    (Parameter : Parameter_Type)
      --     --  UPPER INTERMEDIATE SECTION
      --   with Aspect
      --   when Barrier
      --  is
      --     --  LOWER INTERMEDIATE SECTION

      --------------------------------
      -- Intermediate_Section_Range --
      --------------------------------

      procedure Intermediate_Section_Range
        (Decl_Node        : Libadalang.Analysis.Entry_Body'Class;
         Name_Node        : Defining_Name'Class;
         Family_Node      : Entry_Index_Spec'Class;
         Params_Node      : Params'Class;
         Aspects_Node     : Aspect_Spec'Class;
         Barrier_Node     : Expr'Class;
         Upper_Start_Line : out Line_Number;
         Upper_End_Line   : out Line_Number;
         Lower_Start_Line : out Line_Number;
         Lower_End_Line   : out Line_Number);
      --  Range of the "intermediate" section for subprogram.

      --------------------------------
      -- Intermediate_Section_Range --
      --------------------------------

      procedure Intermediate_Section_Range
        (Decl_Node        : Libadalang.Analysis.Entry_Body'Class;
         Name_Node        : Defining_Name'Class;
         Family_Node      : Entry_Index_Spec'Class;
         Params_Node      : Params'Class;
         Aspects_Node     : Aspect_Spec'Class;
         Barrier_Node     : Expr'Class;
         Upper_Start_Line : out Line_Number;
         Upper_End_Line   : out Line_Number;
         Lower_Start_Line : out Line_Number;
         Lower_End_Line   : out Line_Number)
      is

      begin
         if Params_Node /= No_Params then
            --  For entry body with parameters, upper intermediate section
            --  starts after the parameters.

            Upper_Start_Line := Params_Node.Sloc_Range.End_Line + 1;

         elsif not Family_Node.Is_Null then
            --  For entry family body without parameters, upper intermediate
            --  section starts after the entry family index declaration.

            Upper_Start_Line := Family_Node.Sloc_Range.End_Line + 1;

         else
            --  For entry without family index and parameters, upper
            --  intermediate section starts after the entry defining name.

            Upper_Start_Line := Name_Node.Sloc_Range.End_Line + 1;
         end if;

         if not Aspects_Node.Is_Null then
            --  Aspects declaration ends upper intermediate section.

            Upper_End_Line := Aspects_Node.Sloc_Range.Start_Line - 1;

         else
            --  Barrier condition is always present and ends upper
            --  intermediate section.

            Upper_End_Line := Barrier_Node.Sloc_Range.Start_Line - 1;
         end if;

         Lower_Start_Line := Barrier_Node.Sloc_Range.End_Line + 1;
         Lower_End_Line   := Decl_Node.Sloc_Range.End_Line;
      end Intermediate_Section_Range;

      Name_Node    : constant Defining_Name := Decl_Node.F_Entry_Name;
      Family_Node  : constant Entry_Index_Spec'Class :=
        Decl_Node.F_Index_Spec;
      Params_Node  : constant Params'Class := Decl_Node.F_Params.F_Params;
      Aspects_Node : constant Aspect_Spec'Class := Decl_Node.F_Aspects;
      Barrier_Node : constant Expr'Class := Decl_Node.F_Barrier;

      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;
      Intermediate_Lower_Section : Section_Access;
      Trailing_Section           : Section_Access;
      Last_Section               : Section_Access;
      Minimum_Indent             : Column_Number;
      Components_Builder         :
        GNATdoc.Comments.Builders.Subprograms.Subprogram_Components_Builder;

   begin
      --  Create intermediate "raw" sections to collect documentation of
      --  the entry body, exact range is used to fill comments after the end
      --  of the subprogram specification and before the name of the first
      --  aspect association, thus, location of the "when" keyword is not
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
        (Decl_Node,
         Name_Node,
         Family_Node,
         Params_Node,
         Aspects_Node,
         Barrier_Node,
         Intermediate_Upper_Section.Exact_Start_Line,
         Intermediate_Upper_Section.Exact_End_Line,
         Intermediate_Lower_Section.Exact_Start_Line,
         Intermediate_Lower_Section.Exact_End_Line);
      Documentation.Sections.Append (Intermediate_Upper_Section);
      Documentation.Sections.Append (Intermediate_Lower_Section);

      --  Create sections for family index and parameters.

      Components_Builder.Build
        (Sections       => Documentation.Sections'Unchecked_Access,
         Options        => Options,
         Node           => Decl_Node,
         Spec_Node      => No_Base_Subp_Spec,
         Name_Node      => Name_Node,
         Family_Node    => Family_Node,
         Params_Node    => Params_Node,
         Returns_Node   => No_Type_Expr,
         Last_Section   => Last_Section,
         Minimum_Indent => Minimum_Indent);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Decl_Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Sections         => Documentation.Sections,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      --  Extract code snippet of declaration and remove all comments from
      --  it.

      declare
         Last_Token         : Token_Reference :=
           (if Aspects_Node.Is_Null
            then Barrier_Node.Token_Start
            else Aspects_Node.Token_Start);
         With_Or_When_Found : Boolean := not Aspects_Node.Is_Null;
         --  First token of the aspects specification is 'with' keyword, while
         --  first token of the barrier expression is expression itself.

      begin
         --  Move to the token before the 'with'/'when' keyword.

         loop
            Last_Token := Previous (Last_Token);

            case Kind (Data (Last_Token)) is
               when Ada_When =>
                  With_Or_When_Found := True;

               when Ada_Whitespace | Ada_Comment =>
                  null;

               when others =>
                  exit when With_Or_When_Found;

                  raise Program_Error;
            end case;
         end loop;

         Fill_Code_Snippet
           (Decl_Node,
            Decl_Node.Token_Start,
            Last_Token,
            Documentation.Sections);
      end;

      --  Postprocess extracted text, for each group of lines, separated
      --  by empty line by remove of two minus signs and common leading
      --  whitespaces

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

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
            Documentation.Sections);
      end;
   end Extract_Entry_Body_Documentation;

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
      Last_Section      : Section_Access;
      Minimum_Indent    : Column_Number;
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;
      Component_Builder :
        GNATdoc.Comments.Builders.Enumerations.Enumeration_Components_Builder;

   begin
      Component_Builder.Build
        (Documentation.Sections'Unchecked_Access,
         Options,
         Node,
         Enum_Node,
         Last_Section,
         Minimum_Indent);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Sections         => Documentation.Sections,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet
        (Node, Node.Token_Start, Node.Token_End, Documentation.Sections);

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

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
            Documentation.Sections);
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
      Sections         : in out Section_Vectors.Vector;
      Leading_Section  : out not null Section_Access;
      Trailing_Section : out not null Section_Access) is
   begin
      Extract_Leading_Section
        (Decl_Node.Token_Start, Options, False, Sections, Leading_Section);
      Extract_General_Trailing_Documentation
        (Decl_Node,
         Options.Pattern,
         Last_Section,
         Minimum_Indent,
         Sections,
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
      Sections         : in out Section_Vectors.Vector;
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
      Sections.Append (Trailing_Section);

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

   ----------------------------------------
   -- Extract_Generic_Decl_Documentation --
   ----------------------------------------

   procedure Extract_Generic_Decl_Documentation
     (Node          : Libadalang.Analysis.Generic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      function Lookup_Formal_Section
        (Name : Defining_Name'Class) return not null Section_Access;

      ---------------------------
      -- Lookup_Formal_Section --
      ---------------------------

      function Lookup_Formal_Section
        (Name : Defining_Name'Class) return not null Section_Access
      is
         Symbol : constant VSS.Strings.Virtual_String :=
           GNATdoc.Comments.Utilities.To_Symbol (Name);

      begin
         for Section of Documentation.Sections loop
            if Section.Kind = Formal and Section.Symbol = Symbol then
               return Section;
            end if;
         end loop;

         raise Program_Error;
      end Lookup_Formal_Section;

      Component_Builder :
        GNATdoc.Comments.Builders.Generics.Generic_Components_Builder;
      Decl              : constant Basic_Decl'Class :=
        (case Node.Kind is
            when Ada_Generic_Package_Decl =>
              Node.As_Generic_Package_Decl.F_Package_Decl,
            when Ada_Generic_Subp_Decl    =>
              Node.As_Generic_Subp_Decl.F_Subp_Decl,
            when others                   => raise Program_Error);

   begin
      Component_Builder.Build
        (Documentation.Sections'Unchecked_Access,
         Options,
         Node,
         Node.F_Formal_Part,
         Decl);

      case Node.Kind is
         when Ada_Generic_Package_Decl =>
            Extract_Base_Package_Decl_Documentation
              (Node,
               Node.As_Generic_Package_Decl.F_Package_Decl,
               Options,
               Documentation);

         when Ada_Generic_Subp_Decl =>
            Extract_Subprogram_Documentation
              (Decl.As_Generic_Subp_Internal,
               Decl.As_Generic_Subp_Internal.F_Subp_Spec,
               No_Expr,
               No_Aspect_Spec,
               Options,
               Documentation.Sections);

         when others =>
            raise Program_Error;
      end case;

      for Item of Node.F_Formal_Part.F_Decls loop
         case Item.Kind is
            when Ada_Generic_Formal_Type_Decl =>
               case Item.As_Generic_Formal_Type_Decl.F_Decl.Kind is
                  when Ada_Incomplete_Formal_Type_Decl =>
                     declare
                        Formal_Name : constant Defining_Name :=
                          Item.As_Generic_Formal_Type_Decl.F_Decl
                            .As_Incomplete_Formal_Type_Decl.F_Name;

                     begin
                        Extract_Simple_Declaration_Documentation
                          (Item.As_Generic_Formal_Type_Decl,
                           Options,
                           Lookup_Formal_Section (Formal_Name).Sections);
                     end;

                  when Ada_Formal_Type_Decl =>
                     declare
                        Type_Decl       : constant Formal_Type_Decl :=
                          Item.As_Generic_Formal_Type_Decl.F_Decl
                            .As_Formal_Type_Decl;
                        Formal_Type_Def : constant Type_Def :=
                          Type_Decl.F_Type_Def;
                        Formal_Name     : constant Defining_Name :=
                          Type_Decl.F_Name;

                     begin
                        case Formal_Type_Def.Kind is
                           when Ada_Private_Type_Def =>
                              Extract_Private_Type_Documentation
                                (Item.As_Generic_Formal_Type_Decl,
                                 Type_Decl,
                                 Options,
                                 Lookup_Formal_Section (Formal_Name).Sections);

                           when Ada_Type_Access_Def
                              | Ada_Array_Type_Def
                              | Ada_Decimal_Fixed_Point_Def
                              | Ada_Derived_Type_Def
                              | Ada_Floating_Point_Def
                              | Ada_Formal_Discrete_Type_Def
                              | Ada_Interface_Type_Def
                              | Ada_Mod_Int_Type_Def
                              | Ada_Ordinary_Fixed_Point_Def
                              | Ada_Signed_Int_Type_Def
                           =>
                              Extract_Simple_Declaration_Documentation
                                (Item.As_Generic_Formal_Type_Decl,
                                 Options,
                                 Lookup_Formal_Section (Formal_Name).Sections);

                           when Ada_Access_To_Subp_Def =>
                              Extract_Subprogram_Documentation
                                (Decl_Node    =>
                                   Item.As_Generic_Formal_Type_Decl,
                                 Spec_Node    =>
                                   Formal_Type_Def.As_Access_To_Subp_Def
                                     .F_Subp_Spec,
                                 Expr_Node    => No_Expr,
                                 Aspects_Node => No_Aspect_Spec,
                                 Options      => Options,
                                 Sections     =>
                                   Lookup_Formal_Section
                                     (Formal_Name).Sections);

                           when others =>
                              raise Program_Error;
                        end case;
                     end;

                  when others =>
                     raise Program_Error;
               end case;

            when Ada_Generic_Formal_Subp_Decl =>
               declare
                  Subp_Decl        : constant Concrete_Formal_Subp_Decl :=
                    Item.As_Generic_Formal_Subp_Decl.F_Decl
                      .As_Concrete_Formal_Subp_Decl;
                  Formal_Subp_Spec : constant Subp_Spec :=
                    Subp_Decl.F_Subp_Spec;
                  Formal_Name      : constant Defining_Name :=
                    Formal_Subp_Spec.F_Subp_Name;

               begin
                  Extract_Subprogram_Documentation
                    (Decl_Node    => Item.As_Generic_Formal_Subp_Decl,
                     Spec_Node    => Formal_Subp_Spec,
                     Expr_Node    => No_Expr,
                     Aspects_Node => No_Aspect_Spec,
                     Options      => Options,
                     Sections     =>
                       Lookup_Formal_Section (Formal_Name).Sections);
               end;

            when Ada_Generic_Formal_Obj_Decl =>
               declare
                  Ids : constant Defining_Name_List :=
                    Item.As_Generic_Formal_Obj_Decl.F_Decl
                      .As_Object_Decl.F_Ids;

               begin
                  for Id of Ids loop
                     Extract_Simple_Declaration_Documentation
                       (Item.As_Generic_Formal_Obj_Decl,
                        Options,
                        Lookup_Formal_Section (Id).Sections);
                  end loop;
               end;

            when Ada_Generic_Formal_Package =>
               Extract_Simple_Declaration_Documentation
                 (Item.As_Generic_Formal_Package,
                  Options,
                  Lookup_Formal_Section
                    (Item.As_Generic_Formal_Package.F_Decl
                       .As_Generic_Package_Instantiation.F_Name).Sections);

            when Ada_Pragma_Node =>
               --  Nothing to do for pragmas.

               null;

            when others =>
               raise Program_Error;
         end case;
      end loop;
   end Extract_Generic_Decl_Documentation;

   -----------------------------
   -- Extract_Leading_Section --
   -----------------------------

   procedure Extract_Leading_Section
     (Token_Start       : Token_Reference;
      Options           : GNATdoc.Comments.Options.Extractor_Options;
      Separator_Allowed : Boolean;
      Sections          : in out Section_Vectors.Vector;
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
      Sections.Append (Section);

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

   ----------------------------------------
   -- Extract_Private_Type_Documentation --
   ----------------------------------------

   procedure Extract_Private_Type_Documentation
     (Node     : Libadalang.Analysis.Basic_Decl'Class;
      Decl     : Libadalang.Analysis.Type_Decl'Class;
      Options  : GNATdoc.Comments.Options.Extractor_Options;
      Sections : in out Section_Vectors.Vector)
   is
      Last_Section      : Section_Access;
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;

      Component_Builder :
        GNATdoc.Comments.Builders.Private_Types.Private_Type_Builder;
      Minimum_Indent    : Column_Number := 0;

   begin
      Component_Builder.Build
        (Sections'Unchecked_Access,
         Options,
         Decl,
         Last_Section,
         Minimum_Indent);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Sections         => Sections,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet (Node, Node.Token_Start, Node.Token_End, Sections);

      Remove_Comment_Start_And_Indentation (Sections, Options.Pattern);

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
            Sections);
      end;
   end Extract_Private_Type_Documentation;

   ------------------------------------------
   -- Extract_Protected_Body_Documentation --
   ------------------------------------------

   procedure Extract_Protected_Body_Documentation
     (Node          : Libadalang.Analysis.Protected_Body'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class)
   is
      Is_Token                   : Token_Reference :=
        (if Node.F_Aspects.Is_Null
           then Node.F_Name.Token_End else Node.F_Aspects.Token_End);
      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;

   begin
      Extract_Leading_Section
        (Node.Token_Start,
         Options,
         True,
         Documentation.Sections,
         Leading_Section);

      --  Lookup for 'is' token that begins protected body.

      loop
         Is_Token := Next (Is_Token);

         exit when Is_Token = No_Token;

         case Kind (Data (Is_Token)) is
            when Ada_Whitespace | Ada_Comment =>
               null;

            when Ada_Is =>
               exit;

            when others =>
               raise Program_Error;
         end case;
      end loop;

      Extract_Upper_Intermediate_Section
        (Is_Token,
         Node.Token_End,
         Options,
         Documentation,
         Intermediate_Upper_Section);

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

      declare
         Raw_Section : Section_Access;

      begin
         --  Select most appropriate section.

         if Intermediate_Upper_Section /= null
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
            Documentation.Sections,
            Documentation.Is_Private);
      end;
   end Extract_Protected_Body_Documentation;

   ------------------------------------------
   -- Extract_Protected_Decl_Documentation --
   ------------------------------------------

   procedure Extract_Protected_Decl_Documentation
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Definition    : Libadalang.Analysis.Protected_Def'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : in out Structured_Comment'Class)
   is
      Is_Or_With_Token           : Token_Reference;
      Leading_Section            : Section_Access;
      Intermediate_Upper_Section : Section_Access;
      Component_Builder          :
        GNATdoc.Comments.Builders.Protecteds.Protected_Components_Builder;

   begin
      Component_Builder.Build
        (Documentation.Sections'Unchecked_Access, Options, Node);

      Extract_Leading_Section
        (Node.Token_Start,
         Options,
         True,
         Documentation.Sections,
         Leading_Section);

      --  Lookup for 'is' token that begins protected definition, or 'with'
      --  token that ends interface part.

      Is_Or_With_Token := Definition.Token_Start;

      loop
         Is_Or_With_Token := Previous (Is_Or_With_Token);

         exit when Is_Or_With_Token = No_Token;

         case Kind (Data (Is_Or_With_Token)) is
            when Ada_Whitespace | Ada_Comment =>
               null;

            when Ada_Is | Ada_With =>
               exit;

            when others =>
               raise Program_Error;
         end case;
      end loop;

      Extract_Upper_Intermediate_Section
        (Is_Or_With_Token,
         Definition.Token_End,
         Options,
         Documentation,
         Intermediate_Upper_Section);

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

      declare
         Raw_Section : Section_Access;

      begin
         --  Select most appropriate section.

         if Intermediate_Upper_Section /= null
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
            Documentation.Sections,
            Documentation.Is_Private);
      end;
   end Extract_Protected_Decl_Documentation;

   ---------------------------------------
   -- Extract_Record_Type_Documentation --
   ---------------------------------------

   procedure Extract_Record_Type_Documentation
     (Node          : Libadalang.Analysis.Type_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
   is
      Last_Section      : Section_Access;
      Minimum_Indent    : Column_Number;
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;
      Component_Builder :
        GNATdoc.Comments.Builders.Records.Record_Components_Builder;

   begin
      Component_Builder.Build
        (Documentation.Sections'Unchecked_Access,
         Options,
         Node,
         Last_Section,
         Minimum_Indent);

      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => Last_Section,
         Minimum_Indent   => Minimum_Indent,
         Sections         => Documentation.Sections,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet
        (Node, Node.Token_Start, Node.Token_End, Documentation.Sections);

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

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
            Documentation.Sections);
      end;
   end Extract_Record_Type_Documentation;

   ----------------------------------------------
   -- Extract_Simple_Declaration_Documentation --
   ----------------------------------------------

   procedure Extract_Simple_Declaration_Documentation
     (Node     : Libadalang.Analysis.Basic_Decl'Class;
      Options  : GNATdoc.Comments.Options.Extractor_Options;
      Sections : in out Section_Vectors.Vector)
   is
      Leading_Section   : Section_Access;
      Trailing_Section  : Section_Access;

   begin
      Extract_General_Leading_Trailing_Documentation
        (Decl_Node        => Node,
         Options          => Options,
         Last_Section     => null,
         Minimum_Indent   => 0,
         Sections         => Sections,
         Leading_Section  => Leading_Section,
         Trailing_Section => Trailing_Section);

      Fill_Code_Snippet (Node, Node.Token_Start, Node.Token_End, Sections);
      Remove_Comment_Start_And_Indentation (Sections, Options.Pattern);

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

         Parse_Raw_Section (Raw_Section, (others => False), Sections);
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
      Definition                 : constant
        Libadalang.Analysis.Task_Def'Class := Decl.F_Definition;
      Is_Or_With_Token           : Token_Reference;

      Leading_Section            : Section_Access;
      Trailing_Section           : Section_Access;
      Intermediate_Upper_Section : Section_Access;

   begin
      Extract_Leading_Section
        (Node.Token_Start,
         Options,
         True,
         Documentation.Sections,
         Leading_Section);

      if Definition.Is_Null then
         --  It is the case of the entry-less and definition-less task
         --  declaration. Documentation may be provided by the comment
         --  immidiately below task declaration. Retreive it into the
         --  tailing section.

         Extract_General_Trailing_Documentation
           (Node,
            Options.Pattern,
            null,
            0,
            Documentation.Sections,
            Trailing_Section);

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

      Remove_Comment_Start_And_Indentation
        (Documentation.Sections, Options.Pattern);

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
            Documentation.Sections,
            Documentation.Is_Private);
      end;
   end Extract_Single_Task_Decl_Documentation;

   --------------------------------------
   -- Extract_Subprogram_Documentation --
   --------------------------------------

   procedure Extract_Subprogram_Documentation
     (Decl_Node    : Libadalang.Analysis.Basic_Decl'Class;
      Spec_Node    : Libadalang.Analysis.Base_Subp_Spec'Class;
      Expr_Node    : Expr'Class;
      Aspects_Node : Aspect_Spec'Class;
      Options      : GNATdoc.Comments.Options.Extractor_Options;
      Sections     : in out Section_Vectors.Vector)
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
      Declarative_Section        : Section_Access;
      Trailing_Section           : Section_Access;
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
      Sections.Append (Intermediate_Upper_Section);
      Sections.Append (Intermediate_Lower_Section);

      --  Create sections for parameters and return value.

      Components_Builder.Build
        (Sections       => Sections'Unchecked_Access,
         Options        => Options,
         Node           => Decl_Node,
         Spec_Node      => Spec_Node,
         Name_Node      => Name_Node,
         Family_Node    => Libadalang.Analysis.No_Entry_Index_Spec,
         Params_Node    => Params_Node,
         Returns_Node   => Returns_Node,
         Last_Section   => Last_Section,
         Minimum_Indent => Minimum_Indent);

      Extract_Leading_Section
        (Decl_Node.Token_Start, Options, False, Sections, Leading_Section);

      if Decl_Node.Kind = Ada_Subp_Body then
         --  Extract comments before and after 'is' keyword.

         Declarative_Section :=
           new Section'
             (Kind   => Raw,
              Symbol => "<<DECLARATIVE>>",
              Name   => <>,
              Text   => <>,
              others => <>);
         Sections.Append (Declarative_Section);

         declare
            Token : Token_Reference :=
              Decl_Node.As_Subp_Body.F_Decls.Token_Start;
            Reset : Boolean := False;

         begin
            --  Process comments on top of declarative section.

            loop
               Token := Previous (Token);

               exit when Token = No_Token;

               case Kind (Data (Token)) is
                  when Ada_Comment =>
                     if Reset then
                        Reset := False;
                        Declarative_Section.Text.Clear;
                     end if;

                     Prepend_Documentation_Line
                       (Declarative_Section.Text,
                        Text (Token),
                        Options.Pattern);

                  when Ada_Whitespace =>
                     declare
                        Location : constant Source_Location_Range :=
                          Sloc_Range (Data (Token));

                     begin
                        if Location.End_Line - Location.Start_Line > 1 then
                           Reset := True;
                        end if;
                     end;

                  when others =>
                     exit;
               end case;
            end loop;

            --  Process lower intermediate section.

            Reset := False;

            loop
               Token := Previous (Token);

               exit when Token = No_Token;

               case Kind (Data (Token)) is
                  when Ada_Comment =>
                     if Reset then
                        Reset := False;
                        Intermediate_Lower_Section.Text.Clear;
                     end if;

                     Prepend_Documentation_Line
                       (Intermediate_Lower_Section.Text,
                        Text (Token),
                        Options.Pattern);

                  when Ada_Whitespace =>
                     declare
                        Location : constant Source_Location_Range :=
                          Sloc_Range (Data (Token));

                     begin
                        if Location.End_Line - Location.Start_Line > 1 then
                           --  exit;
                           Reset := True;
                        end if;
                     end;

                  when others =>
                     exit;
               end case;
            end loop;
         end;

      else
         --  Extract comments after the subprogram declaration.

         Extract_General_Trailing_Documentation
           (Decl_Node,
            Options.Pattern,
            Last_Section,
            Minimum_Indent,
            Sections,
            Trailing_Section);
      end if;

      --  Extract code snippet of declaration and remove all comments from
      --  it.

      if Decl_Node.Kind in Ada_Type_Decl then
         --  Access to subprogram type

         Fill_Code_Snippet
           (Decl_Node, Decl_Node.Token_Start, Decl_Node.Token_End, Sections);

      else
         Fill_Code_Snippet
           (Spec_Node, Spec_Node.Token_Start, Spec_Node.Token_End, Sections);
      end if;

      --  Postprocess extracted text, for each group of lines, separated
      --  by empty line by remove of two minus signs and common leading
      --  whitespaces

      Remove_Comment_Start_And_Indentation (Sections, Options.Pattern);

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

               elsif Declarative_Section /= null
                 and then not Declarative_Section.Text.Is_Empty
               then
                  Raw_Section := Declarative_Section;

               elsif Trailing_Section /= null
                 and then not Trailing_Section.Text.Is_Empty
               then
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

                  elsif Declarative_Section /= null
                    and then not Declarative_Section.Text.Is_Empty
                  then
                     Raw_Section := Declarative_Section;

                  elsif Trailing_Section /= null
                    and then not Trailing_Section.Text.Is_Empty
                  then
                     Raw_Section := Trailing_Section;
                  end if;
               end if;
         end case;

         Parse_Raw_Section
           (Raw_Section,
            (Param_Tag | Return_Tag | Exception_Tag => True,
             others                                 => False),
            Sections);
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
     (Node        : Ada_Node'Class;
      First_Token : Token_Reference;
      Last_Token  : Token_Reference;
      Sections    : in out Section_Vectors.Vector)
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
         Line      : constant Virtual_String := Text (Line_Index);
         Iterator  : Character_Iterator      := Line.At_First_Character;
         Count     : Character_Count         := Amount;

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

      First_Token_Location : constant Source_Location_Range :=
        Sloc_Range (Data (First_Token));
      Snippet_Section      : Section_Access;
      Text                 : Virtual_String_Vector;

   begin
      Text :=
        To_Virtual_String
          (Libadalang.Common.Text (First_Token, Last_Token)).Split_Lines
            (Ada_New_Line_Function);

      --  Indent first line correctly.

      declare
         Line : Virtual_String := Text (1);

      begin
         for J in 2 .. First_Token_Location.Start_Column loop
            Line.Prepend (' ');
         end loop;

         Text.Replace (1, Line);
      end;

      --  Remove comments

      if First_Token /= Last_Token then
         declare
            Line_Offset : constant Line_Number :=
              First_Token_Location.Start_Line - 1;
            Token       : Token_Reference      := Last_Token;

         begin
            loop
               Token := Previous (Token);

               exit when Token = First_Token or Token = No_Token;

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

                     --  Remove comment and spaces before it from the line.

                     Line := Line.Slice (Line.At_First_Character, Iterator);
                     Text.Replace (Index, Line);
                  end;
               end if;
            end loop;
         end;
      end if;

      --  For enumeration types with large number of defined enumeration
      --  literals, limit text for few first literals and last literal.

      if Node.Kind = Ada_Concrete_Type_Decl
        and then Node.As_Concrete_Type_Decl.F_Type_Def.Kind
                   = Ada_Enum_Type_Def
      then
         declare
            procedure Move_At
              (Iterator : in out Character_Iterator;
               Position : Character_Index);

            -------------
            -- Move_At --
            -------------

            procedure Move_At
              (Iterator : in out Character_Iterator;
               Position : Character_Index) is
            begin
               if Iterator.Character_Index = Position then
                  return;

               elsif Iterator.Character_Index < Position then
                  while Iterator.Forward loop
                     exit when Iterator.Character_Index = Position;
                  end loop;

               else
                  while Iterator.Backward loop
                     exit when Iterator.Character_Index = Position;
                  end loop;
               end if;
            end Move_At;

            Max_Enum_Literals : constant := 10;
            --  Maximum number of the enumeration literals presented in the
            --  code snippet.

            Line_Offset : constant Line_Number :=
              First_Token_Location.Start_Line - 1;
            Literals    : constant Enum_Literal_Decl_List :=
              Node.As_Concrete_Type_Decl.F_Type_Def.As_Enum_Type_Def
                .F_Enum_Literals;

         begin
            if Literals.Children_Count > Max_Enum_Literals then
               --  Replace enumeration literal before the last enumeration
               --  literal of the type by the horizontal ellipsis.

               declare
                  Location   : constant Source_Location_Range :=
                    Literals.Child (Literals.Last_Child_Index - 1).Sloc_Range;
                  Index      : constant Positive :=
                    Positive (Location.Start_Line - Line_Offset);
                  Line       : Virtual_String := Text (Index);
                  E_Iterator : Character_Iterator :=
                    Line.After_Last_Character;
                  S_Iterator : Character_Iterator :=
                    Line.After_Last_Character;

               begin
                  Move_At
                    (S_Iterator, Character_Index (Location.Start_Column));
                  Move_At
                    (E_Iterator, Character_Index (Location.End_Column) - 1);
                  Line.Replace (S_Iterator, E_Iterator, "…");
                  Text.Replace (Index, Line);
               end;

               --  Remove all other intermediate enumeration literals.

               for J in reverse
                 Literals.First_Child_Index + Max_Enum_Literals - 2
                   .. Literals.Last_Child_Index - 2
               loop
                  declare
                     Location   : constant Source_Location_Range :=
                       Literals.Child (J).Sloc_Range;
                     Index      : constant Positive :=
                       Positive (Location.Start_Line - Line_Offset);
                     Line       : Virtual_String := Text (Index);
                     E_Iterator : Character_Iterator :=
                       Line.After_Last_Character;
                     S_Iterator : Character_Iterator :=
                       Line.After_Last_Character;

                  begin
                     Move_At
                       (S_Iterator, Character_Index (Location.Start_Column));
                     Move_At
                       (E_Iterator, Character_Index (Location.End_Column) - 1);

                     while S_Iterator.Backward loop
                        exit when not Is_Ada_Separator (S_Iterator.Element);
                     end loop;

                     if S_Iterator.Has_Element then
                        Line.Delete (S_Iterator, E_Iterator);
                        Text.Replace (Index, Line);

                     else
                        Line.Delete (Line.At_First_Character, E_Iterator);

                        declare
                           Previous : Virtual_String := Text (Index - 1);

                        begin
                           E_Iterator.Set_At_Last (Previous);
                           Previous.Delete
                             (E_Iterator, Previous.At_Last_Character);
                           Previous.Append (Line);
                           Text.Replace (Index - 1, Previous);
                           Text.Delete (Index);
                        end;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end if;

      --  Remove all empty lines

      for Index in reverse 1 .. Text.Length loop
         if Text (Index).Is_Empty then
            Text.Delete (Index);
         end if;
      end loop;

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
              and then First_Token_Location.Start_Line
                         = Indicator_Location.Start_Line
            then
               Offset :=
                 VSS.Strings.Character_Count
                   (First_Token_Location.Start_Column
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
                                  = First_Token_Location.Start_Line
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
      Sections.Append (Snippet_Section);
   end Fill_Code_Snippet;

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
      Sections      : in out Section_Vectors.Vector)
   is
      Aux : Boolean := False;

   begin
      Parse_Raw_Section (Raw_Section, Allowed_Tags, Sections, Aux);
   end Parse_Raw_Section;

   -----------------------
   -- Parse_Raw_Section --
   -----------------------

   procedure Parse_Raw_Section
     (Raw_Section   : Section_Access;
      Allowed_Tags  : Section_Tag_Flags;
      Sections      : in out Section_Vectors.Vector;
      Is_Private    : in out Boolean)
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
      Sections.Append (Current_Section);

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
               Kind := Formal;

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
               Is_Private := True;

               goto Skip;

            elsif Kind
              in Parameter | Raised_Exception | Enumeration_Literal | Field
                   | Formal
            then
               --  Lookup for name of the parameter/exception. Convert
               --  found name to canonical form.

               --  Match := Parameter_Matcher.Match (Line, Tail_First);
               --  ??? Not implemented

               Match := Parameter_Matcher.Match (Line_Tail);

               if not Match.Has_Match then
                  goto Default;
               end if;

               Name      := Match.Captured (1);
               Symbol    := GNATdoc.Comments.Utilities.To_Symbol (Name);
               Line_Tail := Line_Tail.Tail_After (Match.Last_Marker);

            else
               Name.Clear;
               Symbol.Clear;
            end if;

            declare
               Found : Boolean := False;

            begin
               for Section of Sections loop
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
                     Sections.Append (Current_Section);

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

      for Section of Sections loop
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
     (Sections : in out Section_Vectors.Vector;
      Pattern  : VSS.Regular_Expressions.Regular_Expression) is
   begin
      for Section of Sections loop
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
                              Match : constant Regular_Expression_Match :=
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
                     Success  : Boolean with Unreferenced;

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
