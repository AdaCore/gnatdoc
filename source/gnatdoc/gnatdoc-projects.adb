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

with Ada.Containers.Hashed_Sets;
with Ada.Strings.Hash;
with Ada.Text_IO;

with Langkit_Support.Text;
with Libadalang.Common;
with Libadalang.Iterators;
with Libadalang.Project_Provider;

with GPR2.Context;
with GPR2.Path_Name;
with GPR2.Project.Attribute;
with GPR2.Project.Attribute_Index;
with GPR2.Project.Tree;
with GPR2.Project.Registry.Attribute;
with GPR2.Project.Registry.Pack;

with VSS.Application;
with VSS.Command_Line;
with VSS.Regular_Expressions;
with VSS.Strings.Conversions;

with GNATdoc.Command_Line;
with GNATdoc.Messages;
with GNATdoc.Options;

package body GNATdoc.Projects is

   use type GNATCOLL.VFS.Virtual_File;

   Documentation_Package                : constant GPR2.Package_Id :=
     GPR2."+" ("documentation");

   Documentation_Pattern_Attribute      : constant GPR2.Attribute_Id :=
     GPR2."+" ("documentation_pattern");
   Excluded_Project_Files_Attribute     : constant GPR2.Attribute_Id :=
     GPR2."+" ("excluded_project_files");
   Output_Dir_Attribute                 : constant GPR2.Attribute_Id :=
     GPR2."+" ("output_dir");
   Resources_Dir_Attribute              : constant GPR2.Attribute_Id :=
     GPR2."+" ("resources_dir");

   Documentation_Documentation_Pattern  : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Documentation_Pattern_Attribute);
   Documentation_Excluded_Project_Files : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Excluded_Project_Files_Attribute);
   Documentation_Output_Dir             : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Output_Dir_Attribute);
   Documentation_Resources_Dir          : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Resources_Dir_Attribute);

   type Missing_File_Event_Handler is
     new Libadalang.Analysis.Event_Handler_Interface with null record;
   --  Collect critical unit resolution failures in global object. It is used
   --  to report errors.

   overriding procedure Unit_Requested_Callback
     (Self               : in out Missing_File_Event_Handler;
      Context            : Libadalang.Analysis.Analysis_Context'Class;
      Name               : Langkit_Support.Text.Text_Type;
      From               : Libadalang.Analysis.Analysis_Unit'Class;
      Found              : Boolean;
      Is_Not_Found_Error : Boolean);

   overriding procedure Release
     (Self : in out Missing_File_Event_Handler) is null;

   function Hash
     (Item : GNATCOLL.VFS.Virtual_File) return Ada.Containers.Hash_Type;

   package Virtual_File_Sets is
     new Ada.Containers.Hashed_Sets
       (GNATCOLL.VFS.Virtual_File, Hash, GNATCOLL.VFS."=");

   Project_Tree          : GPR2.Project.Tree.Object;
   Exclude_Project_Files : Virtual_File_Sets.Set;
   LAL_Context           : Libadalang.Analysis.Analysis_Context;
   Event_Handler         : Libadalang.Analysis.Event_Handler_Reference;
   Missing_Files         : Virtual_File_Sets.Set;

   procedure Register_Attributes;

   --------------------------------
   -- Custom_Resources_Directory --
   --------------------------------

   function Custom_Resources_Directory
     (Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File
   is
      Index       : constant GPR2.Project.Attribute_Index.Object :=
        GPR2.Project.Attribute_Index.Create
          (VSS.Strings.Conversions.To_UTF_8_String (Backend_Name));
      Backend_Dir : constant GNATCOLL.VFS.Filesystem_String :=
        GNATCOLL.VFS.Filesystem_String
          (VSS.Strings.Conversions.To_UTF_8_String (Backend_Name));

   begin
      return Result : GNATCOLL.VFS.Virtual_File := GNATCOLL.VFS.No_File do
         if Project_Tree.Root_Project.Has_Attribute
           (Documentation_Resources_Dir, Index)
         then
            declare
               Attribute : constant GPR2.Project.Attribute.Object :=
                 Project_Tree.Root_Project.Attribute
                   (Documentation_Resources_Dir, Index);

            begin
               Result :=
                 GNATCOLL.VFS.Create_From_Base
                   (GNATCOLL.VFS.Filesystem_String
                      (Attribute.Value.Text),
                    Project_Tree.Root_Project.Dir_Name.Virtual_File
                      .Full_Name.all);

               if Attribute.Index.Text
                 /= VSS.Strings.Conversions.To_UTF_8_String (Backend_Name)
               then
                  Result := Result / Backend_Dir;
               end if;
            end;
         end if;
      end return;
   end Custom_Resources_Directory;

   ----------
   -- Hash --
   ----------

   function Hash
     (Item : GNATCOLL.VFS.Virtual_File) return Ada.Containers.Hash_Type is
   begin
      return Ada.Strings.Hash (Item.Display_Full_Name);
   end Hash;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      Project_Context : GPR2.Context.Object :=
        GNATdoc.Command_Line.Project_Context;

   begin
      Register_Attributes;

      --  Export GPR_TOOL scenario variable when necessary

      if not Project_Context.Contains ("GPR_TOOL")
        and not VSS.Application.System_Environment.Contains ("GPR_TOOL")
      then
         Project_Context.Insert ("GPR_TOOL", "gnatdoc");
      end if;

      --  Load project file

      begin
         Project_Tree.Load_Autoconf
           (GPR2.Path_Name.Create_File
              (GPR2.Filename_Type
                   (VSS.Strings.Conversions.To_UTF_8_String
                        (GNATdoc.Command_Line.Project_File))),
            Project_Context);

         Project_Tree.Update_Sources (With_Runtime => True);

      exception
         when GPR2.Project_Error =>
            for Message of Project_Tree.Log_Messages.all loop
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error, Message.Format);
            end loop;

            raise;
      end;

      --  Create Libadalang context and unit provider

      Event_Handler :=
        Libadalang.Analysis.Create_Event_Handler_Reference
          (Missing_File_Event_Handler'(null record));

      LAL_Context :=
        Libadalang.Analysis.Create_Context
          (Unit_Provider =>
             Libadalang.Project_Provider.Create_Project_Unit_Provider
               (Project_Tree),
           Event_Handler => Event_Handler);
      LAL_Context.Discard_Errors_In_Populate_Lexical_Env (False);

      --  Setup list of excluded project files

      if Project_Tree.Root_Project.Has_Attribute
        (Documentation_Excluded_Project_Files)
      then
         declare
            Attribute : constant GPR2.Project.Attribute.Object :=
              Project_Tree.Root_Project.Attribute
                (Documentation_Excluded_Project_Files);

         begin
            for Item of Attribute.Values loop
               if Item.Text'Length = 0 then
                  VSS.Command_Line.Report_Error
                    ("empty name of the project file");
               end if;

               if Project_Tree.Get_File
                    (GPR2.Filename_Type
                       (Item.Text)).Virtual_File = GNATCOLL.VFS.No_File
               then
                  VSS.Command_Line.Report_Error
                    ("unable to resolve project file path");
               end if;

               Exclude_Project_Files.Insert
                 (Project_Tree.Get_File
                    (GPR2.Filename_Type (Item.Text)).Virtual_File);
            end loop;
         end;
      end if;

      --  Set documentation pattern

      if Project_Tree.Root_Project.Has_Attribute
        (Documentation_Documentation_Pattern)
      then
         declare
            Attribute : constant GPR2.Project.Attribute.Object :=
              Project_Tree.Root_Project.Attribute
                (Documentation_Documentation_Pattern);

         begin
            GNATdoc.Options.Extractor_Options.Pattern :=
              VSS.Regular_Expressions.To_Regular_Expression
                (VSS.Strings.Conversions.To_Virtual_String
                   (Attribute.Value.Text));
         end;
      end if;
   end Initialize;

   ----------------------
   -- Output_Directory --
   ----------------------

   function Output_Directory
     (Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File
   is
      Index       : constant GPR2.Project.Attribute_Index.Object :=
        GPR2.Project.Attribute_Index.Create
          (VSS.Strings.Conversions.To_UTF_8_String (Backend_Name));
      Backend_Dir : constant GNATCOLL.VFS.Filesystem_String :=
        GNATCOLL.VFS.Filesystem_String
          (VSS.Strings.Conversions.To_UTF_8_String (Backend_Name));

   begin
      return Result : GNATCOLL.VFS.Virtual_File do
         if Project_Tree.Root_Project.Kind in GPR2.With_Object_Dir_Kind then
            Result :=
              Project_Tree.Root_Project.Object_Directory.Virtual_File
                / "gnatdoc" / Backend_Dir;
         end if;

         if Project_Tree.Root_Project.Has_Attribute
           (Documentation_Output_Dir, Index)
         then
            declare
               Attribute : constant GPR2.Project.Attribute.Object :=
                 Project_Tree.Root_Project.Attribute
                   (Documentation_Output_Dir, Index);

            begin
               Result :=
                 GNATCOLL.VFS.Create_From_Base
                   (GNATCOLL.VFS.Filesystem_String (Attribute.Value.Text),
                    Project_Tree.Root_Project.Dir_Name.Virtual_File
                      .Full_Name.all);

               if Attribute.Index.Text
                 /= VSS.Strings.Conversions.To_UTF_8_String (Backend_Name)
               then
                  Result := Result / Backend_Dir;
               end if;
            end;
         end if;
      end return;
   end Output_Directory;

   -------------------------------
   -- Process_Compilation_Units --
   -------------------------------

   procedure Process_Compilation_Units
     (Handler : not null access procedure
        (Node : Libadalang.Analysis.Compilation_Unit'Class)) is
   begin
      for View of Project_Tree loop
         if not View.Is_Externally_Built
           and then not Exclude_Project_Files.Contains
                          (View.Path_Name.Virtual_File)
         then
            for Source of View.Sources loop
               if Source.Is_Ada then
                  Missing_Files.Clear;

                  declare
                     use type VSS.Strings.Virtual_String;

                     Unit     : constant Libadalang.Analysis.Analysis_Unit :=
                       LAL_Context.Get_From_File
                         (String (Source.Path_Name.Name));
                     Iterator : Libadalang.Iterators.Traverse_Iterator'Class :=
                       Libadalang.Iterators.Find
                         (Unit.Root,
                          Libadalang.Iterators.Kind_Is
                            (Libadalang.Common.Ada_Compilation_Unit));
                     Node     : Libadalang.Analysis.Ada_Node;

                  begin
                     Unit.Populate_Lexical_Env;

                     if Missing_Files.Is_Empty then
                        while Iterator.Next (Node) loop
                           Handler (Node.As_Compilation_Unit);
                        end loop;

                     else
                        GNATdoc.Messages.Report_Error
                          ((VSS.Strings.Conversions.To_Virtual_String
                           (String (Source.Path_Name.Name)),
                           1,
                           1),
                           "ignore file due to missing dependencies");

                        for File of Missing_Files loop
                           GNATdoc.Messages.Report_Error
                             ((VSS.Strings.Conversions.To_Virtual_String
                              (String (Source.Path_Name.Name)),
                              1,
                              1),
                              "file "
                              & VSS.Strings.Conversions.To_Virtual_String
                                (File.Display_Base_Name)
                              & " is not found");
                        end loop;
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end loop;
   end Process_Compilation_Units;

   -------------------------
   -- Register_Attributes --
   -------------------------

   procedure Register_Attributes is
   begin
      GPR2.Project.Registry.Pack.Add
        (Documentation_Package, GPR2.Project.Registry.Pack.Everywhere);

      GPR2.Project.Registry.Attribute.Add
        (Name                 => Documentation_Documentation_Pattern,
         Index_Type           => GPR2.Project.Registry.Attribute.No_Index,
         Value                => GPR2.Project.Registry.Attribute.Single,
         Value_Case_Sensitive => True,
         Is_Allowed_In        => GPR2.Project.Registry.Attribute.Everywhere);

      GPR2.Project.Registry.Attribute.Add
        (Name                 => Documentation_Output_Dir,
         Index_Type           => GPR2.Project.Registry.Attribute.String_Index,
         Value                => GPR2.Project.Registry.Attribute.Single,
         Value_Case_Sensitive => True,
         Is_Allowed_In        => GPR2.Project.Registry.Attribute.Everywhere,
         Index_Optional       => True);

      GPR2.Project.Registry.Attribute.Add
        (Name                 => Documentation_Resources_Dir,
         Index_Type           => GPR2.Project.Registry.Attribute.String_Index,
         Value                => GPR2.Project.Registry.Attribute.Single,
         Value_Case_Sensitive => True,
         Is_Allowed_In        => GPR2.Project.Registry.Attribute.Everywhere,
         Index_Optional       => True);

      GPR2.Project.Registry.Attribute.Add
        (Name                 => Documentation_Excluded_Project_Files,
         Index_Type           => GPR2.Project.Registry.Attribute.No_Index,
         Value                => GPR2.Project.Registry.Attribute.List,
         Value_Case_Sensitive => True,
         Is_Allowed_In        => GPR2.Project.Registry.Attribute.Everywhere);
   end Register_Attributes;

   -----------------------------
   -- Unit_Requested_Callback --
   -----------------------------

   overriding procedure Unit_Requested_Callback
     (Self               : in out Missing_File_Event_Handler;
      Context            : Libadalang.Analysis.Analysis_Context'Class;
      Name               : Langkit_Support.Text.Text_Type;
      From               : Libadalang.Analysis.Analysis_Unit'Class;
      Found              : Boolean;
      Is_Not_Found_Error : Boolean) is
   begin
      if not Found and Is_Not_Found_Error then
         Missing_Files.Include
           (GNATCOLL.VFS.Create_From_UTF8
              (VSS.Strings.Conversions.To_UTF_8_String
                   (VSS.Strings.To_Virtual_String (Name))));
      end if;
   end Unit_Requested_Callback;

end GNATdoc.Projects;
