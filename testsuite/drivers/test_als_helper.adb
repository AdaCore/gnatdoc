------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
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

--  Test driver to run ALS helper subprograms on set of nodes and dump
--  results.

with VSS.Application;
with VSS.Command_Line;
with VSS.JSON.Pull_Readers.JSON5;
with VSS.JSON.Streams;
with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.String_Vectors;
with VSS.Text_Streams.File_Input;
with VSS.Text_Streams.Standards;

with GPR2.Build.Source.Sets;
with GPR2.Options;
with GPR2.Project.Tree;

with Libadalang.Analysis;
with Libadalang.Common;

with GNATdoc.Comments.Debug;
with GNATdoc.Comments.Extractor;
with GNATdoc.Comments.Helpers;
with GNATdoc.Comments.Options;

procedure Test_ALS_Helper is

   Output  : VSS.Text_Streams.Output_Text_Stream'Class
     renames VSS.Text_Streams.Standards.Standard_Output;
   Context : Libadalang.Analysis.Analysis_Context;

   procedure Print
     (Text : VSS.Strings.Virtual_String;
      Node : Libadalang.Analysis.Ada_Node'Class);

   procedure Extract_And_Dump
     (File   : VSS.Strings.Virtual_String;
      Line   : Libadalang.Slocs.Line_Number;
      Column : Libadalang.Slocs.Column_Number);

   procedure Load_And_Process_Locations
     (File_Name : VSS.Strings.Virtual_String);

   ----------------------
   -- Extract_And_Dump --
   ----------------------

   procedure Extract_And_Dump
     (File   : VSS.Strings.Virtual_String;
      Line   : Libadalang.Slocs.Line_Number;
      Column : Libadalang.Slocs.Column_Number)
   is
      Unit   : Libadalang.Analysis.Analysis_Unit;
      Origin : Libadalang.Analysis.Ada_Node;
      Name   : Libadalang.Analysis.Defining_Name;

      Code_Snippet  : VSS.String_Vectors.Virtual_String_Vector;
      Documentation : VSS.String_Vectors.Virtual_String_Vector;
      Success       : Boolean := True;

   begin
      Unit :=
        Context.Get_From_File
          (Filename => VSS.Strings.Conversions.To_UTF_8_String (File));
      Origin := Unit.Root.Lookup (Sloc => (Line => Line, Column => Column));

      case Origin.Kind is
         when Libadalang.Common.Ada_Identifier =>
            Name :=
              (if Origin.As_Identifier.P_Is_Defining
                 then Origin.As_Identifier.P_Enclosing_Defining_Name
                 else Origin.As_Identifier.P_Referenced_Defining_Name);

         when others =>
            Origin.Print;
            Unit.Root.Print;

            raise Program_Error;
      end case;

      Print ("Defining name", Name);
      Print ("Origin", Origin);

      GNATdoc.Comments.Helpers.Get_Plain_Text_Documentation
        (Name          => Name,
         Origin        => Origin,
         Options       =>
           (Style    => GNATdoc.Comments.Options.GNAT,
            Pattern  => <>,
            Fallback => True),
         Code_Snippet  => Code_Snippet,
         Documentation => Documentation);

      Output.Put_Line ("----- CODE SNIPPET -----", Success);

      for Line of Code_Snippet loop
         Output.Put_Line (Line, Success);
      end loop;

      Output.Put_Line ("----- DOCUMENTATION -----", Success);

      for Line of Documentation loop
         Output.Put_Line (Line, Success);
      end loop;

      Output.Put_Line ("----- DONE -----", Success);
   end Extract_And_Dump;

   --------------------------------
   -- Load_And_Process_Locations --
   --------------------------------

   procedure Load_And_Process_Locations
     (File_Name : VSS.Strings.Virtual_String)
   is
      use type VSS.Strings.Virtual_String;

      Stream : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader : VSS.JSON.Pull_Readers.JSON5.JSON5_Pull_Reader;

      Key    : VSS.Strings.Virtual_String;
      File   : VSS.Strings.Virtual_String;
      Line   : Libadalang.Slocs.Line_Number;
      Column : Libadalang.Slocs.Column_Number;

   begin
      Stream.Open (File_Name, "utf-8");
      Reader.Set_Stream (Stream'Unchecked_Access);

      while not Reader.At_End loop
         case Reader.Read_Next is
            when VSS.JSON.Streams.Start_Document
               | VSS.JSON.Streams.Start_Array
               | VSS.JSON.Streams.Start_Object
               | VSS.JSON.Streams.End_Array
               | VSS.JSON.Streams.End_Document
            =>
               null;

            when VSS.JSON.Streams.Key_Name =>
               Key := Reader.Key_Name;

            when VSS.JSON.Streams.String_Value =>
               if Key = "file" then
                  File := Reader.String_Value;

               else
                  raise Program_Error;
               end if;

            when VSS.JSON.Streams.Number_Value =>
               if Key = "line" then
                  Line :=
                    Libadalang.Slocs.Line_Number
                      (Reader.Number_Value.Integer_Value);

               elsif Key = "column" then
                  Column :=
                    Libadalang.Slocs.Column_Number
                      (Reader.Number_Value.Integer_Value);

               else
                  raise Program_Error;
               end if;

            when VSS.JSON.Streams.End_Object =>
               Extract_And_Dump (File, Line, Column);

            when others =>
               raise Program_Error
                 with VSS.JSON.Streams.JSON_Stream_Element_Kind'Image
                        (Reader.Element_Kind);
         end case;
      end loop;
   end Load_And_Process_Locations;

   -----------
   -- Print --
   -----------

   procedure Print
     (Text : VSS.Strings.Virtual_String;
      Node : Libadalang.Analysis.Ada_Node'Class)
   is
      Success  : Boolean := True;
      Template : constant VSS.Strings.Templates.Virtual_String_Template :=
        "{}: {}";

   begin
      Output.Put_Line
        (Template.Format
           (VSS.Strings.Formatters.Strings.Image (Text),
            VSS.Strings.Formatters.Strings.Image
              (VSS.Strings.Conversions.To_Virtual_String
                 (Node.Image))),
         Success);
   end Print;

begin
   --  Load project, create LAL context, and parse source code.

   declare
      Options : GPR2.Options.Object;
      Tree    : GPR2.Project.Tree.Object;

   begin
      Options.Add_Switch
        (GPR2.Options.P,
         VSS.Strings.Conversions.To_UTF_8_String
           (VSS.Application.Arguments.Element (1)));

      if not Tree.Load (Options => Options, With_Runtime => True) then
         VSS.Command_Line.Report_Error ("unable to load project file");
      end if;

      Tree.Update_Sources;

      Context := Libadalang.Analysis.Create_Context_From_Project (Tree);
      Context.Discard_Errors_In_Populate_Lexical_Env (False);

      for View of Tree loop
         if not View.Is_Runtime then
            for Source of View.Sources loop
               declare
                  Unit : Libadalang.Analysis.Analysis_Unit :=
                    Context.Get_From_File (String (Source.Path_Name.Name));

               begin
                  Unit.Populate_Lexical_Env;
               end;
            end loop;
         end if;
      end loop;
   end;

   --  Load and process locations

   Load_And_Process_Locations (VSS.Application.Arguments.Element (2));
end Test_ALS_Helper;
