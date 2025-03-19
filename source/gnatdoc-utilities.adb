------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
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

with Langkit_Support.Slocs;

package body GNATdoc.Utilities is

   --------------
   -- Location --
   --------------

   function Location
     (Name : Libadalang.Analysis.Ada_Node'Class)
      return GNATdoc.Source_Location
   is
      Aux : constant Langkit_Support.Slocs.Source_Location_Range :=
        Name.Sloc_Range;

   begin
      return
        (File   =>
           VSS.Strings.Conversions.To_Virtual_String (Name.Unit.Get_Filename),
         Line   => VSS.Strings.Line_Count (Aux.Start_Line),
         Column => VSS.Strings.Character_Count (Aux.Start_Column));
   end Location;

end GNATdoc.Utilities;
