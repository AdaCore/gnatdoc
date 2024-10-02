------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2024, AdaCore                        --
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

package body GNATdoc.Backend.Test is

   Dump_Projects_Option : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "test-dump-projects",
      Description => "Dump list of projects to be processed/excluded");

   ------------------------------
   -- Add_Command_Line_Options --
   ------------------------------

   overriding procedure Add_Command_Line_Options
     (Self   : Test_Backend;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      Parser.Add_Option (Dump_Projects_Option);
   end Add_Command_Line_Options;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out Test_Backend) is
   begin
      if Self.Dump_Projects then
         GNATdoc.Projects.Test_Dump_Projects;
      end if;
   end Generate;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out Test_Backend) is
   begin
      Abstract_Backend (Self).Initialize;
   end Initialize;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out Test_Backend) return VSS.Strings.Virtual_String is
   begin
      return "test";
   end Name;

   ----------------------------------
   -- Process_Command_Line_Options --
   ----------------------------------

   overriding procedure Process_Command_Line_Options
     (Self   : in out Test_Backend;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      Self.Dump_Projects := Parser.Is_Specified (Dump_Projects_Option);
   end Process_Command_Line_Options;

end GNATdoc.Backend.Test;
