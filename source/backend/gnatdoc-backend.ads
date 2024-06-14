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

private with GNATCOLL.VFS;

with VSS.Command_Line.Parsers;
private with VSS.String_Vectors;

private with GNATdoc.Entities;

package GNATdoc.Backend is

   type Abstract_Backend is abstract tagged limited private;

   type Backend_Access is access all Abstract_Backend'Class;

   procedure Add_Command_Line_Options
     (Self   : Abstract_Backend;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class)
        is abstract;
   --  Adds backend specific command line options to the parser. Parsing is
   --  done by the driver later, and Process_Command_Line_Options is called
   --  to obtain values of the options from the command line.

   procedure Process_Command_Line_Options
     (Self   : in out Abstract_Backend;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class) is abstract;
   --  Obtain values of the options specified in command line. In case of
   --  some configuration error, VSS.Command_Line.Report_Error should be
   --  called.

   procedure Initialize (Self : in out Abstract_Backend);

   function Name
     (Self : in out Abstract_Backend)
      return VSS.Strings.Virtual_String is abstract;

   procedure Generate (Self : in out Abstract_Backend) is abstract;

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

   -------------------------
   -- Utility subprograms --
   -------------------------

   function Is_Private_Entity
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return Boolean;
   --  Return True when given entity is private package, or explicitly marked
   --  as private entity, or enclosed by the private package, or enclosed by
   --  the entity marked as private entity.

end GNATdoc.Backend;
