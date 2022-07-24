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

with VSS.Command_Line;
with VSS.String_Vectors;
with VSS.Strings.Conversions;

package body GNATdoc.Command_Line is

   Project_Option : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => "P",
      Long_Name   => "project",
      Value_Name  => "project_file",
      Description => "Project file to process");

   Scenario_Option : constant VSS.Command_Line.Name_Value_Option :=
     (Short_Name  => "X",
      Long_Name   => <>,
      Name_Name   => "variable",
      Value_Name  => "value",
      Description => "Set scenario variable");

   Positional_Project_Option : constant VSS.Command_Line.Positional_Option :=
     (Name        => "project_file",
      Description => "Project file to process");

   Project_File_Argument     : VSS.Strings.Virtual_String;
   Project_Context_Arguments : GPR2.Context.Object;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      Positional : VSS.String_Vectors.Virtual_String_Vector;

   begin
      VSS.Command_Line.Add_Option (Scenario_Option);
      VSS.Command_Line.Add_Option (Project_Option);
      VSS.Command_Line.Add_Option (Positional_Project_Option);

      VSS.Command_Line.Process;
      Positional := VSS.Command_Line.Positional_Arguments;

      if VSS.Command_Line.Is_Specified (Project_Option) then
         Project_File_Argument := VSS.Command_Line.Value (Project_Option);
      end if;

      if Project_File_Argument.Is_Empty then
         if Positional.Is_Empty then
            VSS.Command_Line.Report_Error ("no project file specified");
         end if;

         Project_File_Argument := Positional.Element (1);
         Positional.Delete_First;
      end if;

      if not Positional.Is_Empty then
         VSS.Command_Line.Report_Error
           ("more than one project files specified");
      end if;

      for NV of VSS.Command_Line.Values (Scenario_Option) loop
         if NV.Name.Is_Empty then
            VSS.Command_Line.Report_Error
              ("scenario name can't be empty");
         end if;

         Project_Context_Arguments.Insert
           (GPR2.Name_Type (VSS.Strings.Conversions.To_UTF_8_String (NV.Name)),
            VSS.Strings.Conversions.To_UTF_8_String (NV.Value));
      end loop;
   end Initialize;

   ---------------------
   -- Project_Context --
   ---------------------

   function Project_Context return GPR2.Context.Object is
   begin
      return Project_Context_Arguments;
   end Project_Context;

   ------------------
   -- Project_File --
   ------------------

   function Project_File return VSS.Strings.Virtual_String is
   begin
      return Project_File_Argument;
   end Project_File;

end GNATdoc.Command_Line;
