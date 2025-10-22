------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2025, AdaCore                     --
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

private with VSS.Characters;

with Libadalang.Analysis;
with Libadalang.Common;

with GNATdoc.Comments.Options;
with GNATdoc.Messages;

package GNATdoc.Comments.Extractor is

   use all type Libadalang.Common.Ada_Node_Kind_Type;
   use Libadalang.Common;

   procedure Extract
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class;
      Messages      : out GNATdoc.Messages.Message_Container)
     with Pre =>
       Node.Kind in Ada_Abstract_Subp_Decl
                      | Ada_Entry_Body
                      | Ada_Entry_Decl
                      | Ada_Exception_Decl
                      | Ada_Expr_Function
                      | Ada_Generic_Package_Decl
                      | Ada_Generic_Package_Instantiation
                      | Ada_Generic_Package_Renaming_Decl
                      | Ada_Generic_Subp_Decl
                      | Ada_Generic_Subp_Instantiation
                      | Ada_Generic_Subp_Renaming_Decl
                      | Ada_Incomplete_Type_Decl
                      | Ada_Null_Subp_Decl
                      | Ada_Number_Decl
                      | Ada_Object_Decl
                      | Ada_Package_Body
                      | Ada_Package_Decl
                      | Ada_Package_Renaming_Decl
                      | Ada_Protected_Body
                      | Ada_Protected_Type_Decl
                      | Ada_Single_Protected_Decl
                      | Ada_Single_Task_Decl
                      | Ada_Subp_Body
                      | Ada_Subp_Decl
                      | Ada_Subp_Renaming_Decl
                      | Ada_Subtype_Decl
                      | Ada_Task_Type_Decl
         or (Node.Kind in Ada_Type_Decl
               and then Node.As_Type_Decl.F_Type_Def.Kind
                          in Ada_Access_To_Subp_Def
                               | Ada_Array_Type_Def
                               | Ada_Decimal_Fixed_Point_Def
                               | Ada_Derived_Type_Def
                               | Ada_Enum_Type_Def
                               | Ada_Floating_Point_Def
                               | Ada_Interface_Type_Def
                               | Ada_Mod_Int_Type_Def
                               | Ada_Ordinary_Fixed_Point_Def
                               | Ada_Private_Type_Def
                               | Ada_Record_Type_Def
                               | Ada_Signed_Int_Type_Def
                               | Ada_Type_Access_Def);
   --  Extract documentation for supported kinds of nodes.

   function Extract_Formal_Section
     (Documentation : Structured_Comment;
      Name          : Libadalang.Analysis.Defining_Name'Class)
      return Structured_Comment;
   --  Create new structured comment from the section for the formal parameter
   --  of the generic with the given name.

private

   function Is_Ada_Separator
     (Item : VSS.Characters.Virtual_Character) return Boolean;
   --  Return True when given character is Ada's separator.
   --
   --  @param Item Character to be classified
   --  @return Whether given character is Ada's separator or not

   function Count_Leading_Whitespaces
     (Line : VSS.Strings.Virtual_String) return VSS.Strings.Character_Count;
   --  Returns number of leading Ada whitespace characters in the given line.

   function Remove_Leading_Whitespaces
     (Line   : VSS.Strings.Virtual_String;
      Indent : VSS.Strings.Character_Count) return VSS.Strings.Virtual_String;
   --  Removes at most given number of leading whitespaces.

end GNATdoc.Comments.Extractor;
