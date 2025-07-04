------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2024-2025, AdaCore                     --
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

with Libadalang.Analysis;

with VSS.Strings;

package GNATdoc.Projects is

   procedure Register_Attributes;
   --  Register GPR2 documentation attributes.

   procedure Initialize;
   --  Initialize project support, load and process project tree.

   procedure Process_Compilation_Units
     (Handler : not null access procedure
        (Node : Libadalang.Analysis.Compilation_Unit'Class));

   function Project_File_Directory return GNATCOLL.VFS.Virtual_File;
   --  Return directory of the root project.

   function Output_Directory
     (Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File;
   --  Return output directory to generate documentation. It is computed
   --  from the
   --   - value of Documentation'Output_Directory attribute for given backend
   --   - value of Documentation'Output_Directory attribute for any backend
   --     with backend's name subdirectory
   --   - value of Project'Object_Dir with 'gnatdoc' and backend's name
   --     subdirectories.

   function Image_Directories
     (Backend_Name : VSS.Strings.Virtual_String)
      return GNATdoc.Virtual_File_Vectors.Vector;
   --  Returns list of source directories of images.

   function Custom_Resources_Directory
     (Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File;
   --  Return custom resources directory if specified.

   procedure Test_Dump_Projects;
   --  Dump projects to be processed.
   --
   --  This subprogram is intended to be used for testing purpose.

end GNATdoc.Projects;
