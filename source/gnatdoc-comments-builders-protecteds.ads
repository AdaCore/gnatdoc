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

--  Structured comment builder for protected types and objects. It creates
--  sections for components (and discriminants).

with Libadalang.Analysis;
with Libadalang.Common;

package GNATdoc.Comments.Builders.Protecteds is

   use all type Libadalang.Common.Ada_Node_Kind_Type;

   type Protected_Components_Builder is
     new Abstract_Components_Builder with private;

   procedure Build
     (Self          : in out Protected_Components_Builder;
      Documentation : not null GNATdoc.Comments.Structured_Comment_Access;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Node          : Libadalang.Analysis.Basic_Decl'Class)
     with Pre =>
       Node.Kind in Ada_Single_Protected_Decl | Ada_Protected_Type_Decl;

private

   type Protected_Components_Builder is
     new Abstract_Components_Builder with null record;

end GNATdoc.Comments.Builders.Protecteds;
