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

with GNATdoc.Command_Line;

package body GNATdoc.Configuration.Command_Line is

   ------------------
   -- Backend_Name --
   ------------------

   overriding function Backend_Name
     (Self : Command_Line_Configuration_Provider)
      return VSS.Strings.Virtual_String
   is
      Aux : constant VSS.Strings.Virtual_String :=
        GNATdoc.Command_Line.Backend_Name;

   begin
      if not Aux.Is_Empty then
         return Aux;

      else
         return Abstract_Configuration_Provider (Self).Backend_Name;
      end if;
   end Backend_Name;

   ---------------------
   -- Backend_Options --
   ---------------------

   overriding function Backend_Options
     (Self : Command_Line_Configuration_Provider)
      return VSS.String_Vectors.Virtual_String_Vector
   is
   begin
      if GNATdoc.Command_Line.Is_Backend_Options_Specified then
         return GNATdoc.Command_Line.Backend_Options;

      else
         return Abstract_Configuration_Provider (Self).Backend_Options;
      end if;
   end Backend_Options;

   ----------------------
   -- Output_Directory --
   ----------------------

   overriding function Output_Directory
     (Self         : Command_Line_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File
   is
      use type GNATCOLL.VFS.Virtual_File;

      Aux : constant GNATCOLL.VFS.Virtual_File :=
        GNATdoc.Command_Line.Output_Directory;

   begin
      if Aux /= GNATCOLL.VFS.No_File then
         return Aux;

      else
         return
           Abstract_Configuration_Provider
             (Self).Output_Directory (Backend_Name);
      end if;
   end Output_Directory;

   ----------------------
   -- Warnings_Enabled --
   ----------------------

   overriding function Warnings_Enabled
     (Self : Command_Line_Configuration_Provider) return Boolean is
   begin
      return GNATdoc.Command_Line.Warnings;
   end Warnings_Enabled;

end GNATdoc.Configuration.Command_Line;
