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

package body GNATdoc.Configuration is

   ------------------
   -- Backend_Name --
   ------------------

   not overriding function Backend_Name
     (Self : Abstract_Configuration_Provider)
      return VSS.Strings.Virtual_String is
   begin
      if Self.Child /= null then
         return Self.Child.Backend_Name;

      else
         return "html";
      end if;
   end Backend_Name;

   --------------------------------
   -- Custom_Resources_Directory --
   --------------------------------

   not overriding function Custom_Resources_Directory
     (Self         : Abstract_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File is
   begin
      if Self.Child /= null then
         return Self.Child.Custom_Resources_Directory (Backend_Name);

      else
         return GNATCOLL.VFS.No_File;
      end if;
   end Custom_Resources_Directory;

   ----------------------
   -- Output_Directory --
   ----------------------

   not overriding function Output_Directory
     (Self         : Abstract_Configuration_Provider;
      Backend_Name : VSS.Strings.Virtual_String)
      return GNATCOLL.VFS.Virtual_File is
   begin
      if Self.Child /= null then
         return Self.Child.Output_Directory (Backend_Name);

      else
         return GNATCOLL.VFS.No_File;
      end if;
   end Output_Directory;

   ----------------------
   -- Warnings_Enabled --
   ----------------------

   not overriding function Warnings_Enabled
     (Self : Abstract_Configuration_Provider) return Boolean is
   begin
      if Self.Child /= null then
         return Self.Child.Warnings_Enabled;

      else
         return False;
      end if;
   end Warnings_Enabled;

end GNATdoc.Configuration;
