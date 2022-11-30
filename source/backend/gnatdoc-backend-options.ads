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

with VSS.String_Vectors;

package GNATdoc.Backend.Options is

   type Backend_Kind is (HTML, Jekyll);

   type Backend_Options is record
      Backend : Backend_Kind := Backend_Kind'First;
      --  Which backend to use

      Output_Directory : VSS.Strings.Virtual_String :=
        VSS.Strings.Empty_Virtual_String;
      --  Custom output directory

      Resource_Directory : VSS.Strings.Virtual_String :=
        VSS.Strings.Empty_Virtual_String;
      --  Custom reource directory

      Jekyll_Front_Matter : VSS.String_Vectors.Virtual_String_Vector :=
        VSS.String_Vectors.Empty_Virtual_String_Vector;
      --  Custom lines in Jekyll Front Matter header
   end record;

end GNATdoc.Backend.Options;
