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

with VSS.Strings.Conversions;

package body GNATdoc.Projects is

   Documentation_Package : constant GPR2.Package_Id :=
     GPR2."+" ("documentation");
   Output_Dir_Attribute  : constant GPR2.Attribute_Id :=
     GPR2."+" ("output_dir");

   Project_Context : GPR2.Context.Object;
   Project_Tree    : GPR2.Project.Tree.Object;
   LAL_Context     : Libadalang.Analysis.Analysis_Context;

   procedure Register_Attributes;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (File_Name : VSS.Strings.Virtual_String) is
   begin
      Register_Attributes;

      begin
         Project_Tree.Load_Autoconf
           (GPR2.Path_Name.Create_File
              (GPR2.Filename_Type
                   (VSS.Strings.Conversions.To_UTF_8_String
                        (File_Name))),
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

      LAL_Context :=
        Libadalang.Analysis.Create_Context
          (Unit_Provider =>
             Libadalang.GPR2_Provider.Create_Project_Unit_Provider
               (Project_Tree));
   end Initialize;

   ----------------------
   -- Output_Directory --
   ----------------------

   function Output_Directory
     (Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File
   is
      use type GNATCOLL.VFS.Virtual_File;

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
           (Output_Dir_Attribute,
            Documentation_Package,
            Index)
         then
            declare
               Attribute : constant GPR2.Project.Attribute.Object :=
                 Project_Tree.Root_Project.Attribute
                   (Output_Dir_Attribute,
                    Documentation_Package,
                    Index);

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
        (Node : Libadalang.Analysis.Compilation_Unit'Class))
   is
      Sources : GPR2.Project.Source.Set.Object
        := Project_Tree.Root_Project.Sources;

   begin
      for File of Sources loop
         if File.Is_Ada then
            declare
               Unit     : Libadalang.Analysis.Analysis_Unit :=
                 LAL_Context.Get_From_File (String (File.Path_Name.Name));
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
   end Process_Compilation_Units;

   -------------------------
   -- Register_Attributes --
   -------------------------

   procedure Register_Attributes is
   begin
      GPR2.Project.Registry.Pack.Add
        (Documentation_Package, GPR2.Project.Registry.Pack.Everywhere);

      GPR2.Project.Registry.Attribute.Add
        (Name                 =>
           GPR2.Project.Registry.Attribute.Create
             (Output_Dir_Attribute, Documentation_Package),
         Index_Type           => GPR2.Project.Registry.Attribute.String_Index,
         Value => GPR2.Project.Registry.Attribute.Single,
         Value_Case_Sensitive => True,
         Is_Allowed_In        => GPR2.Project.Registry.Attribute.Everywhere,
         Index_Optional       => True);
   end Register_Attributes;

end GNATdoc.Projects;
