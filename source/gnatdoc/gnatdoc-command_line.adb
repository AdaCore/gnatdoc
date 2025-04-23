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

with VSS.Application;
with VSS.Command_Line.Parsers;
with VSS.Strings.Conversions;

with GNATdoc.Comments.Options;
with GNATdoc.Options;
with GNATdoc.Version;

with GPR2.Options;
with GPR2.Project.Registry.Exchange;
with VSS.Strings.Formatters;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

package body GNATdoc.Command_Line is

   Help_Option               : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => "h",
      Long_Name   => "help",
      Description => "Display help information");

   Version_Option            : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "version",
      Description => "Display the program version");

   Backend_Option            : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "backend",
      Value_Name  => "html|odf|rst",
      Description => "Backend to use to generate output");

   Generate_Option           : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "generate",
      Value_Name  => "public|private|body",
      Description => "Part of code to generate documentation");

   Output_Dir_Option         : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => "O",
      Long_Name   => "output-dir",
      Value_Name  => "output_dir",
      Description => "Output directory for generated documentation");

   Project_Option            : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => "P",
      Long_Name   => "project",
      Value_Name  => "project_file",
      Description => "Project file to process");

   Scenario_Option           : constant VSS.Command_Line.Name_Value_Option :=
     (Short_Name  => "X",
      Long_Name   => <>,
      Name_Name   => "name",
      Value_Name  => "value",
      Description => "Specify an external reference for scenario variables");

   Style_Option              : constant VSS.Command_Line.Value_Option :=
     (Short_Name  => <>,
      Long_Name   => "style",
      Value_Name  => "leading|trailing|gnat",
      Description => "Use given style of documentation");

   Warnings_Option           : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "warnings",
      Description => "Report warnings for undocumented entities");

   Verbose_Option            : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => "v",
      Long_Name   => "verbose",
      Description => "Enable verbose output");

   Positional_Project_Option : constant VSS.Command_Line.Positional_Option :=
     (Name        => "project_file",
      Description => "Project file to process");

   Print_Gpr_Registry_Option : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => VSS.Strings.Conversions.To_Virtual_String
        (GPR2.Options.Print_GPR_Registry_Option
             (GPR2.Options.Print_GPR_Registry_Option'First + 2 ..
                  GPR2.Options.Print_GPR_Registry_Option'Last)),
      Description => "Print GPR Documentation attributes and exit");

   Backend_Name_Argument     : VSS.Strings.Virtual_String;
   Output_Dir_Argument       : GNATCOLL.VFS.Virtual_File;
   Project_File_Argument     : VSS.Strings.Virtual_String;
   Project_Context_Arguments : GPR2.Context.Object;
   Warnings_Argument         : Boolean         := False;
   Verbosity                 : Verbosity_Level := Normal;

   Parser                    : VSS.Command_Line.Parsers.Command_Line_Parser;

   -------------------------
   -- Add_Backend_Options --
   -------------------------

   procedure Add_Backend_Options
     (Backend : GNATdoc.Backend.Abstract_Backend'Class) is

   begin
      Backend.Add_Command_Line_Options (Parser);
   end Add_Backend_Options;

   ------------------
   -- Backend_Name --
   ------------------

   function Backend_Name return VSS.Strings.Virtual_String is
   begin
      return Backend_Name_Argument;
   end Backend_Name;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Parser.Add_Option (Help_Option);
      Parser.Add_Option (Version_Option);
      Parser.Add_Option (Print_Gpr_Registry_Option);
      Parser.Add_Option (Style_Option);
      Parser.Add_Option (Backend_Option);
      Parser.Add_Option (Generate_Option);
      Parser.Add_Option (Output_Dir_Option);
      Parser.Add_Option (Project_Option);
      Parser.Add_Option (Warnings_Option);
      Parser.Add_Option (Verbose_Option);
      Parser.Add_Option (Scenario_Option);
      Parser.Add_Option (Positional_Project_Option);

      if not Parser.Parse (VSS.Application.Arguments) then
         VSS.Command_Line.Report_Error (Parser.Error_Message);
      end if;

      --  Process backend option

      if Parser.Is_Specified (Backend_Option) then
         Backend_Name_Argument := Parser.Value (Backend_Option);
      end if;
   end Initialize;

   ----------------------
   -- Output_Directory --
   ----------------------

   function Output_Directory return GNATCOLL.VFS.Virtual_File is
   begin
      return Output_Dir_Argument;
   end Output_Directory;

   ----------------------
   -- Output_Verbosity --
   ----------------------

   function Output_Verbosity return Verbosity_Level is
   begin
      return Verbosity;
   end Output_Verbosity;

   -------------
   -- Process --
   -------------

   procedure Process
     (Backend : in out GNATdoc.Backend.Abstract_Backend'Class)
   is
      use type VSS.Strings.Virtual_String;

   begin
      --  Parser

      if not Parser.Parse (VSS.Application.Arguments) then
         VSS.Command_Line.Report_Error (Parser.Error_Message);
      end if;

      --  Process `--help` if specified

      if Parser.Is_Specified (Help_Option) then
         VSS.Command_Line.Report_Message (Parser.Help_Text);
      end if;

      if Parser.Is_Specified (Version_Option) then
         declare
            Template : constant
              VSS.Strings.Templates.Virtual_String_Template :=
                "GNATdoc {}";

         begin
            VSS.Command_Line.Report_Error
              (Template.Format
                 (VSS.Strings.Formatters.Strings.Image
                      (GNATdoc.Version.Version_String)));
         end;
      end if;

      --  Process `--print-gpr-registry` if specified

      if Parser.Is_Specified (Print_Gpr_Registry_Option) then
         declare
            Message : VSS.Strings.Virtual_String;

            procedure Output (Item : String);
            --  Export registry callback

            ------------
            -- Output --
            ------------

            procedure Output (Item : String) is
            begin
               Message.Append
                 (VSS.Strings.Conversions.To_Virtual_String (Item));
            end Output;
         begin
            GPR2.Project.Registry.Exchange.Export (Output => Output'Access);
            VSS.Command_Line.Report_Message (Message);
         end;
      end if;

      --  Extract name of the project file from the option or positional
      --  argument.

      if Parser.Is_Specified (Project_Option)
        and Parser.Is_Specified (Positional_Project_Option)
      then
         VSS.Command_Line.Report_Error ("project file is specified twice");
      end if;

      if Parser.Is_Specified (Project_Option) then
         Project_File_Argument := Parser.Value (Project_Option);

      elsif Parser.Is_Specified (Positional_Project_Option) then
         Project_File_Argument := Parser.Value (Positional_Project_Option);
      end if;

      if Project_File_Argument.Is_Empty then
         VSS.Command_Line.Report_Error ("no project file specified");
      end if;

      --  Create context to process project file

      for NV of Parser.Values (Scenario_Option) loop
         if NV.Name.Is_Empty then
            VSS.Command_Line.Report_Error ("scenario name can't be empty");
         end if;

         Project_Context_Arguments.Insert
           (GPR2.External_Name_Type
              (VSS.Strings.Conversions.To_UTF_8_String (NV.Name)),
            VSS.Strings.Conversions.To_UTF_8_String (NV.Value));
      end loop;

      --  Check and select style of the comments.

      if Parser.Is_Specified (Style_Option) then
         if Parser.Value (Style_Option) = "leading" then
            GNATdoc.Options.Extractor_Options.Style :=
              GNATdoc.Comments.Options.Leading;

         elsif Parser.Value (Style_Option) = "trailing" then
            GNATdoc.Options.Extractor_Options.Style :=
              GNATdoc.Comments.Options.GNAT;

         elsif Parser.Value (Style_Option) = "gnat" then
            GNATdoc.Options.Extractor_Options.Style :=
              GNATdoc.Comments.Options.GNAT;

         else
            VSS.Command_Line.Report_Error ("unsupported style");
         end if;
      end if;

      --  Check and select which parts of the code should be included into
      --  generated documentation.

      if Parser.Is_Specified (Generate_Option) then
         if Parser.Value (Generate_Option) = "public" then
            GNATdoc.Options.Frontend_Options.Generate_Private := False;
            GNATdoc.Options.Frontend_Options.Generate_Body    := False;

         elsif Parser.Value (Generate_Option) = "private" then
            GNATdoc.Options.Frontend_Options.Generate_Private := True;
            GNATdoc.Options.Frontend_Options.Generate_Body    := False;

         elsif Parser.Value (Generate_Option) = "body" then
            GNATdoc.Options.Frontend_Options.Generate_Private := True;
            GNATdoc.Options.Frontend_Options.Generate_Body    := True;

         else
            VSS.Command_Line.Report_Error ("unsupported part of the code");
         end if;
      end if;

      --  Check output dicretory argument.

      if Parser.Is_Specified (Output_Dir_Option) then
         Output_Dir_Argument :=
           GNATCOLL.VFS.Create_From_Base
             (GNATCOLL.VFS.Filesystem_String
                (VSS.Strings.Conversions.To_UTF_8_String
                   (Parser.Value (Output_Dir_Option))),
              GNATCOLL.VFS.Get_Current_Dir.Full_Name);
      end if;

      --  Process warnings command line switch.

      if Parser.Is_Specified (Warnings_Option) then
         Warnings_Argument := True;
      end if;

      --  Verbose output.

      if Parser.Is_Specified (Verbose_Option) then
         Verbosity := Verbose;
      end if;

      --  Call backend to process command line options.

      Backend.Process_Command_Line_Options (Parser);
   end Process;

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

   --------------
   -- Warnings --
   --------------

   function Warnings return Boolean is
   begin
      return Warnings_Argument;
   end Warnings;

end GNATdoc.Command_Line;
