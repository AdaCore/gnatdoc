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

--  Structured comment builder for subprograms and entries.

with Libadalang.Analysis;
with Libadalang.Common;

package GNATdoc.Comments.Builders.Subprograms is

   type Subprogram_Components_Builder is
     new Abstract_Components_Builder with private;

   procedure Build
     (Self            : in out Subprogram_Components_Builder;
      Documentation   : not null GNATdoc.Comments.Structured_Comment_Access;
      Options         : GNATdoc.Comments.Options.Extractor_Options;
      Spec_Node       : Libadalang.Analysis.Base_Subp_Spec'Class;
      Name_Node       : Libadalang.Analysis.Defining_Name'Class;
      Params_Node     : Libadalang.Analysis.Params'Class;
      Returns_Node    : Libadalang.Analysis.Type_Expr'Class;
      Advanced_Groups : out Boolean;
      Last_Section    : out GNATdoc.Comments.Section_Access;
      Minimum_Indent  : out Langkit_Support.Slocs.Column_Number)
     with Pre =>
       Spec_Node.Kind in Libadalang.Common.Ada_Entry_Spec
                       | Libadalang.Common.Ada_Subp_Spec;

private

   type Subprogram_Components_Builder is
     new Abstract_Components_Builder with null record;

end GNATdoc.Comments.Builders.Subprograms;
