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

--  Configuration provider on top of command line.

package GNATdoc.Configuration.Command_Line is

   type Command_Line_Configuration_Provider is
     new Abstract_Configuration_Provider with private;

private

   type Command_Line_Configuration_Provider is
     new Abstract_Configuration_Provider with null record;

   overriding function Backend_Name
     (Self : Command_Line_Configuration_Provider)
      return VSS.Strings.Virtual_String;

   overriding function Output_Directory
     (Self         : Command_Line_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File;
   --  Return output directory to generate documentation.

   overriding function Warnings_Enabled
     (Self : Command_Line_Configuration_Provider) return Boolean;

end GNATdoc.Configuration.Command_Line;
