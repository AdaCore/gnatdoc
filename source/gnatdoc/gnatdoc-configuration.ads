------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2024, AdaCore                     --
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

with GNATCOLL.VFS;

with VSS.Strings;

package GNATdoc.Configuration is

   type Abstract_Configuration_Provider is tagged;

   type Configuration_Provider_Access is
     access all Abstract_Configuration_Provider'Class;

   type Abstract_Configuration_Provider
     (Child : Configuration_Provider_Access := null) is
       abstract tagged limited private;

   not overriding function Backend_Name
     (Self : Abstract_Configuration_Provider)
      return VSS.Strings.Virtual_String;
   --  Return name of the configured backend.

   not overriding function Output_Directory
     (Self         : Abstract_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File;
   --  Return output directory to generate documentation.

   not overriding function Custom_Resources_Directory
     (Self         : Abstract_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File;
   --  Return custom resources directory if specified.

   not overriding function Warnings_Enabled
     (Self : Abstract_Configuration_Provider) return Boolean;
   --  Return True when warnings about undocumented entities are enabled.

   Provider : Configuration_Provider_Access;

private

   type Abstract_Configuration_Provider
     (Child : Configuration_Provider_Access := null) is
        abstract tagged limited null record;

end GNATdoc.Configuration;
