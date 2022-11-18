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

with GNATdoc.Projects;

package body GNATdoc.Configuration.Project is

   --------------------------------
   -- Custom_Resources_Directory --
   --------------------------------

   overriding function Custom_Resources_Directory
     (Self         : Project_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File is
   begin
      return GNATdoc.Projects.Custom_Resources_Directory (Backend_Name);
   end Custom_Resources_Directory;

   ----------------------
   -- Output_Directory --
   ----------------------

   overriding function Output_Directory
     (Self         : Project_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File is
   begin
      return GNATdoc.Projects.Output_Directory (Backend_Name);
   end Output_Directory;

end GNATdoc.Configuration.Project;
