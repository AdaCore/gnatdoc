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

with GNATdoc.Comments.Options;
with GNATdoc.Options;
with GNATdoc.Backend.Options;

package body GNATdoc.Command_Line is

   Generate_Option           : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "generate",
      Value_Name  => "part",
      Description => "Part of code to generate documentation");

   Output_Dir_Option         : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => "O",
      Long_Name   => "output-dir",
      Value_Name  => "output_dir",
      Description => "Output directory for generated documentation");

   Resource_Dir_Option       : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "resource-dir",
      Value_Name  => "resource_dir",
      Description => "Directory for custom resource");

   Project_Option            : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => "P",
      Long_Name   => "project",
      Value_Name  => "project_file",
      Description => "Project file to process");

   Scenario_Option           : constant VSS.Command_Line.Name_Value_Option :=
     (Short_Name  => "X",
      Long_Name   => <>,
      Name_Name   => "variable",
      Value_Name  => "value",
      Description => "Set scenario variable");

   Style_Option              : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "style",
      Value_Name  => "style",
      Description => "Use given style of documentation");

   Positional_Project_Option : constant VSS.Command_Line.Positional_Option :=
     (Name        => "project_file",
      Description => "Project file to process");

   Backend_Option            : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "backend",
      Value_Name  => "backend",
      Description => "Select the gnatdoc backend (html or jekyll)");

   Front_Matter_Option : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "front-matter",
      Value_Name  => "front-matter",
      Description => "Custom line to add in the jekyll output Front Matter");
   --  It should be possible to specify this option mutliple times but this is
   --  not supported in VSS.Command_Line at the moment.

   Project_File_Argument     : VSS.Strings.Virtual_String;
   Project_Context_Arguments : GPR2.Context.Object;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use type VSS.Strings.Virtual_String;

      Positional : VSS.String_Vectors.Virtual_String_Vector;

   begin
      VSS.Command_Line.Add_Option (Generate_Option);
      VSS.Command_Line.Add_Option (Output_Dir_Option);
      VSS.Command_Line.Add_Option (Project_Option);
      VSS.Command_Line.Add_Option (Style_Option);
      VSS.Command_Line.Add_Option (Scenario_Option);
      VSS.Command_Line.Add_Option (Positional_Project_Option);
      VSS.Command_Line.Add_Option (Backend_Option);
      VSS.Command_Line.Add_Option (Front_Matter_Option);

      VSS.Command_Line.Process;
      Positional := VSS.Command_Line.Positional_Arguments;

      --  Extract name of the project file from the option or positional
      --  argument.

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

      --  Create context to process project file

      for NV of VSS.Command_Line.Values (Scenario_Option) loop
         if NV.Name.Is_Empty then
            VSS.Command_Line.Report_Error
              ("scenario name can't be empty");
         end if;

         Project_Context_Arguments.Insert
           (GPR2.Name_Type (VSS.Strings.Conversions.To_UTF_8_String (NV.Name)),
            VSS.Strings.Conversions.To_UTF_8_String (NV.Value));
      end loop;

      --  Check and select style of the comments.

      if VSS.Command_Line.Is_Specified (Style_Option) then
         if VSS.Command_Line.Value (Style_Option) = "leading" then
            GNATdoc.Options.Extractor_Options.Style :=
              GNATdoc.Comments.Options.Leading;

         elsif VSS.Command_Line.Value (Style_Option) = "trailing" then
            GNATdoc.Options.Extractor_Options.Style :=
              GNATdoc.Comments.Options.GNAT;

         elsif VSS.Command_Line.Value (Style_Option) = "gnat" then
            GNATdoc.Options.Extractor_Options.Style :=
              GNATdoc.Comments.Options.GNAT;

         else
            VSS.Command_Line.Report_Error ("unsupported style");
         end if;
      end if;

      --  Check and select which parts of the code should be included into
      --  generated documentation.

      if VSS.Command_Line.Is_Specified (Generate_Option) then
         if VSS.Command_Line.Value (Generate_Option) = "public" then
            GNATdoc.Options.Frontend_Options.Generate_Private := False;
            GNATdoc.Options.Frontend_Options.Generate_Body    := False;

         elsif VSS.Command_Line.Value (Generate_Option) = "private" then
            GNATdoc.Options.Frontend_Options.Generate_Private := True;
            GNATdoc.Options.Frontend_Options.Generate_Body    := False;

         elsif VSS.Command_Line.Value (Generate_Option) = "body" then
            GNATdoc.Options.Frontend_Options.Generate_Private := True;
            GNATdoc.Options.Frontend_Options.Generate_Body    := True;

         else
            VSS.Command_Line.Report_Error ("unsupported part of the code");
         end if;
      end if;

      --  Check output dicretory argument.

      if VSS.Command_Line.Is_Specified (Output_Dir_Option) then

         GNATdoc.Options.Backend_Options.Output_Directory :=
           VSS.Command_Line.Value (Output_Dir_Option);
      end if;

      --  Check resource dicretory argument.

      if VSS.Command_Line.Is_Specified (Resource_Dir_Option) then

         GNATdoc.Options.Backend_Options.Resource_Directory :=
           VSS.Command_Line.Value (Resource_Dir_Option);
      end if;

      --  Check Front Matter argument.

      if VSS.Command_Line.Is_Specified (Front_Matter_Option) then

         GNATdoc.Options.Backend_Options.Jekyll_Front_Matter.Append
           (VSS.Command_Line.Value (Front_Matter_Option));
      end if;

      --  Check backend argument.

      if VSS.Command_Line.Is_Specified (Backend_Option) then

         if VSS.Command_Line.Value (Backend_Option).To_Lowercase = "html" then
            GNATdoc.Options.Backend_Options.Backend :=
              GNATdoc.Backend.Options.HTML;

         elsif VSS.Command_Line.Value (Backend_Option).To_Lowercase = "jekyll"
         then
            GNATdoc.Options.Backend_Options.Backend :=
              GNATdoc.Backend.Options.Jekyll;

         else
            VSS.Command_Line.Report_Error
              ("Unknown backend: '" &
                 VSS.Command_Line.Value (Backend_Option) & "'");
         end if;
      end if;

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
