------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                        Copyright (C) 2025, AdaCore                       --
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

with VSS.Characters.Latin;
with VSS.Strings.Character_Iterators;

package body GNATdoc.Comments.Extractor.Code_Snippets is

   use Libadalang.Analysis;
   use Libadalang.Slocs;
   use VSS.Characters;
   use VSS.Characters.Latin;
   use VSS.Strings;
   use VSS.Strings.Character_Iterators;
   use VSS.String_Vectors;

   Ada_New_Line_Function : constant Line_Terminator_Set :=
     [CR | LF | CRLF => True, others => False];

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

      --  Object declaration of array type with default expression: limit
      --  number of lines of the aggregate to 4.

      if Node.Kind = Ada_Object_Decl
        and then not Node.As_Object_Decl.F_Default_Expr.Is_Null
      then
         declare
            Is_Array : Boolean;

         begin
            if Node.As_Object_Decl.F_Type_Expr.Kind = Ada_Anonymous_Type
              and then Node.As_Object_Decl.F_Type_Expr.As_Anonymous_Type
                .F_Type_Decl.Kind = Ada_Anonymous_Type_Decl
                and then Node.As_Object_Decl.F_Type_Expr.As_Anonymous_Type
                  .F_Type_Decl.As_Anonymous_Type_Decl.F_Type_Def.Kind
                    = Ada_Array_Type_Def
            then
               --  A : array (<range>) of <type> := (<value>, ..., <value>)
               --  A : array (<range>) of <type> := [<value>, ..., <value>]

               Is_Array := True;

            elsif Node.As_Object_Decl.F_Type_Expr.Kind
              = Ada_Subtype_Indication
              and then Node.As_Object_Decl.F_Type_Expr.P_Designated_Type_Decl
                .Kind = Ada_Concrete_Type_Decl
                and then Node.As_Object_Decl.F_Type_Expr.P_Designated_Type_Decl
                  .As_Concrete_Type_Decl.F_Type_Def.Kind = Ada_Array_Type_Def
            then
               --  A : <array_type> := (<value>, ..., <value>)
               --  A : <array_type> := [<value>, ..., <value>]

               Is_Array := True;

            else
               Is_Array := False;
            end if;

            if Is_Array then
               declare
                  Offset       : constant Line_Number :=
                    Sloc_Range (Data (First_Token)).Start_Line - 1;

                  First_Token  : Token_Reference;
                  Last_Token   : Token_Reference;
                  First_Line   : Line_Number;
                  First_Column : Column_Number;
                  Last_Line    : Line_Number;

               begin
                  if Node.As_Object_Decl.F_Default_Expr.Kind
                    = Ada_Bracket_Aggregate
                  then
                     First_Token :=
                       Node.As_Object_Decl.F_Default_Expr.As_Bracket_Aggregate
                         .Token_Start;
                     Last_Token :=
                       Node.As_Object_Decl.F_Default_Expr.As_Bracket_Aggregate
                         .Token_End;

                  elsif Node.As_Object_Decl.F_Default_Expr.Kind
                    = Ada_Aggregate
                  then
                     First_Token :=
                       Node.As_Object_Decl.F_Default_Expr.As_Aggregate
                         .Token_Start;
                     Last_Token :=
                       Node.As_Object_Decl.F_Default_Expr.As_Aggregate
                         .Token_End;

                  else
                     raise Program_Error;
                  end if;

                  First_Line   := Sloc_Range (Data (First_Token)).Start_Line;
                  First_Column := Sloc_Range (Data (First_Token)).Start_Column;
                  Last_Line    := Sloc_Range (Data (Last_Token)).End_Line;

                  if Last_Line - First_Line >= 4 then
                     for J in First_Line + 2 .. Last_Line - 2 loop
                        Text.Delete (Positive (First_Line - Offset + 2));
                     end loop;

                     Text.Replace
                       (Positive (First_Line - Offset + 2),
                        Character_Count (First_Column) * ' ' & "…");
                  end if;
               end;
            end if;
         end;
      end if;

      --  For record type add ';' at the end

      if Node.Kind = Ada_Concrete_Type_Decl
        and then Node.As_Concrete_Type_Decl.F_Type_Def.Kind
                  in Ada_Record_Type_Def | Ada_Derived_Type_Def
        and then not
          (Node.As_Concrete_Type_Decl.F_Type_Def.Kind = Ada_Derived_Type_Def
             and then Node.As_Concrete_Type_Decl.F_Type_Def.As_Derived_Type_Def
                        .F_Record_Extension.Is_Null)
      then
         Text.Replace (Text.Length, Text.Last_Element & ";");
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

      --  Remove indentation

      declare
         Indent : constant VSS.Strings.Character_Count :=
           Count_Leading_Whitespaces (Text (1));

      begin
         for Index in Text.First_Index .. Text.Last_Index loop
            Text.Replace
              (Index, Remove_Leading_Whitespaces (Text (Index), Indent));
         end loop;
      end;

      Snippet_Section :=
        new Section'
          (Kind => Snippet, Symbol => "ada", Text => Text, others => <>);
      Sections.Append (Snippet_Section);
   end Fill_Code_Snippet;

end GNATdoc.Comments.Extractor.Code_Snippets;
