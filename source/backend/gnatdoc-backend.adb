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

with VSS.Application;
with VSS.Strings.Conversions;

with GNATdoc.Projects;

package body GNATdoc.Backend is

   use type GNATCOLL.VFS.Virtual_File;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out Abstract_Backend) is
      Name     : constant VSS.Strings.Virtual_String :=
        Abstract_Backend'Class (Self).Name;
      Exe_Path : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (VSS.Application.Application_File)));

   begin
      Self.System_Resources_Root :=
        Exe_Path.Dir.Get_Parent / "share" / "gnatdoc"
          / GNATCOLL.VFS.Filesystem_String
              (VSS.Strings.Conversions.To_UTF_8_String (Name));
      Self.Project_Resources_Root :=
        GNATdoc.Projects.Custom_Resources_Directory (Name);

      Self.Output_Root := GNATdoc.Projects.Output_Directory (Name);

      --  Create output directory if not exists

      if not Self.Output_Root.Is_Directory then
         Self.Output_Root.Make_Dir;
      end if;
   end Initialize;

   --------------------------
   -- Lookup_Resource_File --
   --------------------------

   function Lookup_Resource_File
     (Self : Abstract_Backend;
      Path : VSS.String_Vectors.Virtual_String_Vector)
      return GNATCOLL.VFS.Virtual_File
   is
      function Build_Path
        (Root : GNATCOLL.VFS.Virtual_File) return GNATCOLL.VFS.Virtual_File;

      ----------------
      -- Build_Path --
      ----------------

      function Build_Path
        (Root : GNATCOLL.VFS.Virtual_File) return GNATCOLL.VFS.Virtual_File is
      begin
         return Result : GNATCOLL.VFS.Virtual_File do
            if Root /= GNATCOLL.VFS.No_File then
               Result := Root;

               for Segment of Path loop
                  Result :=
                    Result
                      / GNATCOLL.VFS.Filesystem_String
                          (VSS.Strings.Conversions.To_UTF_8_String (Segment));
               end loop;
            end if;
         end return;
      end Build_Path;

   begin
      return Result : GNATCOLL.VFS.Virtual_File do
         if Self.Project_Resources_Root /= GNATCOLL.VFS.No_File then
            Result := Build_Path (Self.Project_Resources_Root);
         end if;

         if Result = GNATCOLL.VFS.No_File
           or else not Result.Is_Regular_File
         then
            Result := Build_Path (Self.System_Resources_Root);
         end if;
      end return;
   end Lookup_Resource_File;

end GNATdoc.Backend;
