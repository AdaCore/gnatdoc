------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2026, AdaCore                        --
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

with VSS.Strings;

package GNATdoc.RST_Utilities is

   function RST_Profile
     (Node : Libadalang.Analysis.Subp_Spec'Class)
      return VSS.Strings.Virtual_String;
   --  Return RST rendering of a subprogram profile.

   function RST_Type_Name
     (Type_Decl_Node : Libadalang.Analysis.Type_Expr'Class)
      return VSS.Strings.Virtual_String;
   --  Return normalized type name for a type expression, preserving subtype
   --  attributes (for example, 'Class). For access-to-subprogram types,
   --  RST_Profile is used to render the subprogram specification.

end GNATdoc.RST_Utilities;