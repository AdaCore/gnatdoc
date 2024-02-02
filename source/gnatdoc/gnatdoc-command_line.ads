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

with GPR2.Context;

with VSS.Strings;

with GNATdoc.Backend;

package GNATdoc.Command_Line is

   procedure Initialize;
   --  Configure command line parser and do the first pass of the command line
   --  parsing to detect backend.

   procedure Add_Backend_Options
     (Backend : GNATdoc.Backend.Abstract_Backend'Class);
   --  Register backend's options.

   procedure Process (Backend : in out GNATdoc.Backend.Abstract_Backend'Class);
   --  Parse command line and process command line options.

   function Project_File return VSS.Strings.Virtual_String;
   --  Return path to the project file.

   function Output_Directory return GNATCOLL.VFS.Virtual_File;
   --  Return path to the output directory, specified in the command line.
   --  Return No_File when output directory is not specified.

   function Project_Context return GPR2.Context.Object;
   --  Return prject context.

   function Warnings return Boolean;
   --  Return True when report of the warnings is enabled by the command line
   --  switch.

   function Backend_Name return VSS.Strings.Virtual_String;
   --  Return name of the backend if specified.

end GNATdoc.Command_Line;
