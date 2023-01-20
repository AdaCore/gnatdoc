------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2023, AdaCore                     --
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

private with GNATCOLL.VFS;

with VSS.Strings;
private with VSS.String_Vectors;

package GNATdoc.Backend is

   type Abstract_Backend is abstract tagged limited private;

   type Backend_Access is access all Abstract_Backend'Class;

   procedure Initialize (Self : in out Abstract_Backend);

   function Name
     (Self : in out Abstract_Backend)
      return VSS.Strings.Virtual_String is abstract;

   procedure Generate (Self : in out Abstract_Backend) is abstract;

   function Create_Backend
     (Name : VSS.Strings.Virtual_String) return Backend_Access;

private

   type Abstract_Backend is abstract tagged limited record
      System_Resources_Root  : GNATCOLL.VFS.Virtual_File;
      --  Root directory for system resources. This directory includes
      --  subdirectory for given backend.
      Project_Resources_Root : GNATCOLL.VFS.Virtual_File;
      --  Root directory for project resources. This directory includes
      --  subdirectory for given backend.
      Output_Root            : GNATCOLL.VFS.Virtual_File;
      --  Root directory for output
   end record;

   function Lookup_Resource_File
     (Self : Abstract_Backend;
      Path : VSS.String_Vectors.Virtual_String_Vector)
      return GNATCOLL.VFS.Virtual_File;

end GNATdoc.Backend;
