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

with Ada.Containers.Vectors;

with GNATCOLL.VFS;

with VSS.Strings;

package GNATdoc is

   type Source_Location is record
      File   : VSS.Strings.Virtual_String;
      Line   : VSS.Strings.Line_Count      := 0;
      Column : VSS.Strings.Character_Count := 0;
   end record;

   package Virtual_File_Vectors is
     new Ada.Containers.Vectors
           (Positive, GNATCOLL.VFS.Virtual_File, GNATCOLL.VFS."=");

   Not_Implemented : exception;

end GNATdoc;
