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

with VSS.Command_Line;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with GNATdoc.Command_Line;
with GNATdoc.Configuration.Command_Line;
with GNATdoc.Configuration.Project;
with GNATdoc.Backend.Registry;
with GNATdoc.Frontend;
with GNATdoc.Projects;

procedure GNATdoc.Driver is

   use type GNATdoc.Backend.Backend_Access;

   PF_Provider : aliased
     GNATdoc.Configuration.Project.Project_Configuration_Provider;
   CL_Provider : aliased
     GNATdoc.Configuration.Command_Line.Command_Line_Configuration_Provider
       (PF_Provider'Unchecked_Access);

   Backend : GNATdoc.Backend.Backend_Access;

begin
   --  Configure configuration options provider.

   GNATdoc.Configuration.Provider := CL_Provider'Unchecked_Access;

   --  Register Documentation package & attribute.
   --  Should be done before print-gpr-registry option handling.

   GNATdoc.Projects.Register_Attributes;

   --  Initialize command line.

   GNATdoc.Command_Line.Initialize;

   --  Create backend.

   Backend :=
     GNATdoc.Backend.Registry.Create_Backend
       (GNATdoc.Configuration.Provider.Backend_Name);

   if Backend = null then
      VSS.Command_Line.Report_Error
        (VSS.Strings.Templates.Virtual_String_Template'
           ("unknown backend `{}`").Format
             (VSS.Strings.Formatters.Strings.Image
                  (GNATdoc.Configuration.Provider.Backend_Name)));
   end if;

   --  Register backend's options.

   GNATdoc.Command_Line.Add_Backend_Options (Backend.all);

   --  Process command line.

   GNATdoc.Command_Line.Process (Backend.all);

   --  Initialize projects support.

   GNATdoc.Projects.Initialize;

   --  Initialize backend.

   Backend.Initialize;

   --  Process files

   GNATdoc.Projects.Process_Compilation_Units
     (GNATdoc.Frontend.Process_Compilation_Unit'Access);
   GNATdoc.Frontend.Postprocess;

   --  Generate documentation

   Backend.Generate;
end GNATdoc.Driver;
