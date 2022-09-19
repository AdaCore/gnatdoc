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

with VSS.Strings.Conversions;

with Libadalang.Common;

with GNATdoc.Comments.Extractor;

package body GNATdoc.Comments.Helpers is

   use Libadalang.Analysis;
   use Libadalang.Common;
   use VSS.Strings;
   use VSS.Strings.Conversions;
   use VSS.String_Vectors;

   function Get_Plain_Text_Description
     (Section : not null Section_Access)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Return description as plain text.

   function Get_Plain_Text_Description
     (Documentation : Structured_Comment;
      Name          : Defining_Name'Class)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Return description as plain text.

   --------------------------
   -- Get_Ada_Code_Snippet --
   --------------------------

   function Get_Ada_Code_Snippet
     (Self : Structured_Comment'Class)
      return VSS.String_Vectors.Virtual_String_Vector is
   begin
      for Section of Self.Sections loop
         if Section.Kind = Snippet and Section.Symbol = "ada" then
            return Section.Text;
         end if;
      end loop;

      return VSS.String_Vectors.Empty_Virtual_String_Vector;
   end Get_Ada_Code_Snippet;

   --------------------------------
   -- Get_Plain_Text_Description --
   --------------------------------

   function Get_Plain_Text_Description
     (Section : not null Section_Access)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Text : VSS.String_Vectors.Virtual_String_Vector;

   begin
      case Section.Kind is
         when Formal =>
            Text.Append ("@formal " & Section.Name);

         when Enumeration_Literal =>
            Text.Append ("@enum " & Section.Name);

         when Field =>
            Text.Append ("@field " & Section.Name);

         when Parameter =>
            Text.Append ("@param " & Section.Name);

         when Returns =>
            pragma Assert (Section.Name.Is_Empty);
            Text.Append ("@return");

         when Raised_Exception =>
            Text.Append ("@exception " & Section.Name);

         when others =>
            raise Program_Error;
      end case;

      for Line of Section.Text loop
         Text.Append ("  " & Line);
      end loop;

      return Text;
   end Get_Plain_Text_Description;

   --------------------------------
   -- Get_Plain_Text_Description --
   --------------------------------

   function Get_Plain_Text_Description
     (Documentation : Structured_Comment)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Text : VSS.String_Vectors.Virtual_String_Vector;

   begin
      if Documentation.Has_Documentation then
         --  Copy content of the description section

         for Section of Documentation.Sections loop
            if Section.Kind = Description then
               Text := Section.Text;
            end if;
         end loop;

         --  Process generic formal parameters

         declare
            First_Entry : Boolean := True;

         begin
            for Section of Documentation.Sections loop
               if Section.Kind = Formal then
                  if First_Entry then
                     Text.Append (Empty_Virtual_String);
                     First_Entry := False;
                  end if;

                  Text.Append (Get_Plain_Text_Description (Section));
               end if;
            end loop;
         end;

         --  Process enumeration literals

         declare
            First_Entry : Boolean := True;

         begin
            for Section of Documentation.Sections loop
               if Section.Kind = Enumeration_Literal then
                  if First_Entry then
                     Text.Append (Empty_Virtual_String);
                     First_Entry := False;
                  end if;

                  Text.Append (Get_Plain_Text_Description (Section));
               end if;
            end loop;
         end;

         --  Process fields

         declare
            First_Entry : Boolean := True;

         begin
            for Section of Documentation.Sections loop
               if Section.Kind = Field then
                  if First_Entry then
                     Text.Append (Empty_Virtual_String);
                     First_Entry := False;
                  end if;

                  Text.Append (Get_Plain_Text_Description (Section));
               end if;
            end loop;
         end;

         --  Process parameters

         declare
            First_Entry : Boolean := True;

         begin
            for Section of Documentation.Sections loop
               if Section.Kind = Parameter then
                  if First_Entry then
                     Text.Append (Empty_Virtual_String);
                     First_Entry := False;
                  end if;

                  Text.Append (Get_Plain_Text_Description (Section));
               end if;
            end loop;
         end;

         --  Process return

         declare
            First_Entry : Boolean := True;

         begin
            for Section of Documentation.Sections loop
               if Section.Kind = Returns then
                  if First_Entry then
                     Text.Append (Empty_Virtual_String);
                     First_Entry := False;
                  end if;

                  Text.Append (Get_Plain_Text_Description (Section));
               end if;
            end loop;
         end;

         --  Process raised exceptions

         declare
            First_Entry : Boolean := True;

         begin
            for Section of Documentation.Sections loop
               if Section.Kind = Raised_Exception then
                  if First_Entry then
                     Text.Append (Empty_Virtual_String);
                     First_Entry := False;
                  end if;

                  Text.Append (Get_Plain_Text_Description (Section));
               end if;
            end loop;
         end;
      end if;

      return Text;
   end Get_Plain_Text_Description;

   --------------------------------
   -- Get_Plain_Text_Description --
   --------------------------------

   function Get_Plain_Text_Description
     (Documentation : Structured_Comment;
      Name          : Defining_Name'Class)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Symbol : constant Virtual_String :=
        To_Virtual_String (Name.P_Canonical_Text);

   begin
      for Section of Documentation.Sections loop
         if Section.Kind in Component
           and then Section.Symbol = Symbol
         then
            return Get_Plain_Text_Description (Section);
         end if;
      end loop;

      return Empty_Virtual_String_Vector;
   end Get_Plain_Text_Description;

   ----------------------------------
   -- Get_Plain_Text_Documentation --
   ----------------------------------

   procedure Get_Plain_Text_Documentation
     (Name          : Libadalang.Analysis.Defining_Name'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Code_Snippet  : out VSS.String_Vectors.Virtual_String_Vector;
      Documentation : out VSS.String_Vectors.Virtual_String_Vector)
   is
      Decl            : constant Basic_Decl := Name.P_Basic_Decl;
      Decl_To_Extract : Basic_Decl;
      Name_To_Extract : Defining_Name;

      Extracted : Structured_Comment;

   begin
      if Decl.Kind in Ada_Abstract_Subp_Decl
                    | Ada_Expr_Function
                    | Ada_Generic_Package_Decl
                    | Ada_Generic_Package_Instantiation
                    | Ada_Null_Subp_Decl
                    | Ada_Number_Decl
                    | Ada_Object_Decl
                    | Ada_Package_Decl
                    | Ada_Package_Renaming_Decl
                    | Ada_Subp_Decl
                    | Ada_Subtype_Decl
        or (Decl.Kind in Ada_Type_Decl
            and then Decl.As_Type_Decl.F_Type_Def.Kind
                     in Ada_Access_To_Subp_Def
                      | Ada_Array_Type_Def
                      | Ada_Derived_Type_Def
                      | Ada_Enum_Type_Def
                      | Ada_Interface_Type_Def
                      | Ada_Mod_Int_Type_Def
                      | Ada_Private_Type_Def
                      | Ada_Record_Type_Def
                      | Ada_Signed_Int_Type_Def
                      | Ada_Type_Access_Def)
      then
         Decl_To_Extract := Decl;

      elsif Decl.Kind = Ada_Param_Spec
        and then Decl.P_Parent_Basic_Decl.Kind in Ada_Subp_Decl
      then
         Decl_To_Extract := Decl.P_Parent_Basic_Decl;
         Name_To_Extract := Name.As_Defining_Name;

      elsif Decl.Kind = Ada_Enum_Literal_Decl then
         Decl_To_Extract :=
           Decl.As_Enum_Literal_Decl.P_Enum_Type.As_Basic_Decl;
         Name_To_Extract := Name.As_Defining_Name;

      elsif Decl.Kind in Ada_Discriminant_Spec | Ada_Component_Decl
        and then Decl.P_Parent_Basic_Decl.Kind in Ada_Type_Decl
        and then Decl.P_Parent_Basic_Decl.As_Type_Decl.F_Type_Def.Kind
                   = Ada_Record_Type_Def
      then
         Decl_To_Extract := Decl.P_Parent_Basic_Decl;
         Name_To_Extract := Name.As_Defining_Name;
      end if;

      if not Decl_To_Extract.Is_Null then
         GNATdoc.Comments.Extractor.Extract
           (Decl_To_Extract, Options, Extracted);

         if Name_To_Extract.Is_Null then
            Documentation := Get_Plain_Text_Description (Extracted);

         else
            Documentation :=
              Get_Plain_Text_Description (Extracted, Name_To_Extract);
         end if;

         Code_Snippet  := Get_Ada_Code_Snippet (Extracted);
      end if;
   end Get_Plain_Text_Documentation;

end GNATdoc.Comments.Helpers;
