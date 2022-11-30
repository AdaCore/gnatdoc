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

with GNATdoc.Command_Line;
with GNATdoc.Backend.HTML;
with GNATdoc.Backend.Jekyll;
with GNATdoc.Frontend;
with GNATdoc.Projects;
with GNATdoc.Options;
with GNATdoc.Backend.Options;

procedure GNATdoc.Driver is

   HTML_Backend : aliased GNATdoc.Backend.HTML.HTML_Backend;
   Jekyll_Backend : aliased GNATdoc.Backend.Jekyll.Jekyll_Backend;

   Backend : access GNATdoc.Backend.Abstract_Backend'Class :=
     HTML_Backend'Unchecked_Access;

begin
   GNATdoc.Command_Line.Initialize;
   GNATdoc.Projects.Initialize;

   case GNATdoc.Options.Backend_Options.Backend is
      when GNATdoc.Backend.Options.HTML =>
         Backend := HTML_Backend'Unchecked_Access;
      when GNATdoc.Backend.Options.Jekyll =>
         Backend := Jekyll_Backend'Unchecked_Access;
   end case;

   Backend.Initialize;

   GNATdoc.Projects.Process_Compilation_Units
     (GNATdoc.Frontend.Process_Compilation_Unit'Access);

   Backend.Generate;
end GNATdoc.Driver;
