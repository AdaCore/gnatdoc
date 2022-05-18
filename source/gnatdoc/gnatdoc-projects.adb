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
with GPR2.Project.Source.Set;
with GPR2.Project.Tree;

with VSS.Strings.Conversions;

package body GNATdoc.Projects is

   Project_Context : GPR2.Context.Object;
   Project_Tree    : GPR2.Project.Tree.Object;
   LAL_Context     : Libadalang.Analysis.Analysis_Context;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (File_Name : VSS.Strings.Virtual_String) is
   begin
      begin
         Project_Tree.Load_Autoconf
           (GPR2.Path_Name.Create_File
              (GPR2.Filename_Type
                   (VSS.Strings.Conversions.To_UTF_8_String
                        (File_Name))),
            Project_Context);

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

end GNATdoc.Projects;
