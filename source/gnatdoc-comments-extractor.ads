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

with Libadalang.Analysis;
with Libadalang.Common;

with GNATdoc.Comments.Options;

package GNATdoc.Comments.Extractor is

   use all type Libadalang.Common.Ada_Node_Kind_Type;

   function Extract
     (Node    : Libadalang.Analysis.Basic_Decl'Class;
      Options : GNATdoc.Comments.Options.Extractor_Options)
      return not null Structured_Comment_Access
     with Pre =>
       Node.Kind in Ada_Abstract_Subp_Decl
                      | Ada_Expr_Function
                      | Ada_Subp_Decl
                      | Ada_Null_Subp_Decl
         or (Node.Kind = Ada_Type_Decl
               and then Node.As_Type_Decl.F_Type_Def.Kind
                          in Ada_Enum_Type_Def | Ada_Record_Type_Def);
   --  Extract documentation for supported kinds of nodes.

   procedure Extract
     (Node          : Libadalang.Analysis.Basic_Decl'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Documentation : out Structured_Comment'Class)
     with Pre =>
       Node.Kind in Ada_Abstract_Subp_Decl
                      | Ada_Expr_Function
                      | Ada_Subp_Decl
                      | Ada_Null_Subp_Decl
         or (Node.Kind = Ada_Type_Decl
               and then Node.As_Type_Decl.F_Type_Def.Kind
                          in Ada_Enum_Type_Def | Ada_Record_Type_Def);
   --  Extract documentation for supported kinds of nodes.

   function Extract
     (Node    : Libadalang.Analysis.Basic_Decl'Class;
      Options : GNATdoc.Comments.Options.Extractor_Options)
      return Structured_Comment
     with Pre =>
       Node.Kind in Ada_Abstract_Subp_Decl
                      | Ada_Expr_Function
                      | Ada_Subp_Decl
                      | Ada_Null_Subp_Decl
         or (Node.Kind = Ada_Type_Decl
               and then Node.As_Type_Decl.F_Type_Def.Kind
                          in Ada_Enum_Type_Def | Ada_Record_Type_Def);
   --  Extract documentation for supported kinds of nodes.

end GNATdoc.Comments.Extractor;
