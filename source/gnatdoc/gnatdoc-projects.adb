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

with Ada.Containers.Hashed_Sets;
with Ada.Strings.Hash;
with Ada.Text_IO;

with Libadalang.Common;
with Libadalang.Iterators;
with Libadalang.GPR2_Provider;

with GPR2.Context;
with GPR2.Path_Name;
with GPR2.Project.Attribute;
with GPR2.Project.Attribute_Index;
with GPR2.Project.Source.Set;
with GPR2.Project.Tree;
with GPR2.Project.Registry.Attribute;
with GPR2.Project.Registry.Pack;

with VSS.Command_Line;
with VSS.Strings.Conversions;

with GNATdoc.Command_Line;

package body GNATdoc.Projects is

   use type GNATCOLL.VFS.Virtual_File;

   Documentation_Package                : constant GPR2.Package_Id :=
     GPR2."+" ("documentation");
   Output_Dir_Attribute                 : constant GPR2.Attribute_Id :=
     GPR2."+" ("output_dir");
   Resources_Dir_Attribute              : constant GPR2.Attribute_Id :=
     GPR2."+" ("resources_dir");
   Excluded_Project_Files_Attribute     : constant GPR2.Attribute_Id :=
     GPR2."+" ("excluded_project_files");
   Documentation_Output_Dir             : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Output_Dir_Attribute);
   Documentation_Resources_Dir          : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Resources_Dir_Attribute);
   Documentation_Excluded_Project_Files : constant GPR2.Q_Attribute_Id :=
     (Documentation_Package, Excluded_Project_Files_Attribute);

   function Hash
     (Item : GNATCOLL.VFS.Virtual_File) return Ada.Containers.Hash_Type;

   package Virtual_File_Sets is
     new Ada.Containers.Hashed_Sets
       (GNATCOLL.VFS.Virtual_File, Hash, GNATCOLL.VFS."=");

   Project_Tree          : GPR2.Project.Tree.Object;
   Exclude_Project_Files : Virtual_File_Sets.Set;
   LAL_Context           : Libadalang.Analysis.Analysis_Context;

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
   begin
      Register_Attributes;

      --  Load project file

      begin
         Project_Tree.Load_Autoconf
           (GPR2.Path_Name.Create_File
              (GPR2.Filename_Type
                   (VSS.Strings.Conversions.To_UTF_8_String
                        (GNATdoc.Command_Line.Project_File))),
            GNATdoc.Command_Line.Project_Context);

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

      LAL_Context :=
        Libadalang.Analysis.Create_Context
          (Unit_Provider =>
             Libadalang.GPR2_Provider.Create_Project_Unit_Provider
               (Project_Tree));

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
      return Result : GNATCOLL.VFS.Virtual_File :=
        Project_Tree.Root_Project.Object_Directory.Virtual_File
          / "gnatdoc" / Backend_Dir
      do
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
                  declare
                     Unit     : Libadalang.Analysis.Analysis_Unit :=
                       LAL_Context.Get_From_File
                         (String (Source.Path_Name.Name));
                     Iterator : Libadalang.Iterators.Traverse_Iterator'Class :=
                       Libadalang.Iterators.Find
                         (Unit.Root,
                          Libadalang.Iterators.Kind_Is
                            (Libadalang.Common.Ada_Compilation_Unit));
                     Node     : Libadalang.Analysis.Ada_Node;

                  begin
                     while Iterator.Next (Node) loop
                        Handler (Node.As_Compilation_Unit);
                     end loop;
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

end GNATdoc.Projects;
