------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2023, AdaCore                        --
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

with Ada.Wide_Wide_Text_IO;

with GNATCOLL.VFS;

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Generic_Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.String_Vectors;

package body GNATdoc.Messages is

   use Ada.Wide_Wide_Text_IO;
   use VSS.Strings.Conversions;
   use VSS.Strings.Formatters.Strings;
   use VSS.Strings.Templates;

   function File_Name
     (File : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String;

   package Character_Count_Formatters is
     new VSS.Strings.Formatters.Generic_Integers (VSS.Strings.Character_Count);
   use Character_Count_Formatters;

   package Line_Count_Formatters is
     new VSS.Strings.Formatters.Generic_Integers (VSS.Strings.Line_Count);
   use Line_Count_Formatters;

   ---------------
   -- File_Name --
   ---------------

   function File_Name
     (File : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String
   is
      F : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create_From_UTF8 (To_UTF_8_String (File));

   begin
      return To_Virtual_String (F.Display_Base_Name);
   end File_Name;

   ------------------
   -- Report_Error --
   ------------------

   procedure Report_Error
     (Location : GNATdoc.Entities.Entity_Location;
      Message  : VSS.Strings.Virtual_String)
   is
      Template : Virtual_String_Template := "{}:{}:{}: {}";

   begin
      Put_Line
        (Standard_Error,
         To_Wide_Wide_String
           (Template.Format
                (Image (File_Name (Location.File)),
                 Image (Location.Line),
                 Image (Location.Column),
                 Image (Message))));
   end Report_Error;

   ---------------------------
   -- Report_Internal_Error --
   ---------------------------

   procedure Report_Internal_Error
     (Location   : GNATdoc.Entities.Entity_Location;
      Occurrence : Ada.Exceptions.Exception_Occurrence)
   is
      use type VSS.Strings.Virtual_String;

      Lines : constant VSS.String_Vectors.Virtual_String_Vector :=
        VSS.Strings.Conversions.To_Virtual_String
          (Ada.Exceptions.Exception_Information (Occurrence)).Split_Lines;

   begin
      if Lines.Length = 1 then
         GNATdoc.Messages.Report_Error
           (Location, "internal error: " & Lines (1));

      else
         GNATdoc.Messages.Report_Error (Location, "internal error:");

         for Line of Lines loop
            GNATdoc.Messages.Report_Error (Location, Line);
         end loop;
      end if;
   end Report_Internal_Error;

   --------------------
   -- Report_Warning --
   --------------------

   procedure Report_Warning
     (Location : GNATdoc.Entities.Entity_Location;
      Message  : VSS.Strings.Virtual_String)
   is
      Template : Virtual_String_Template := "{}:{}:{}: warning: {}";

   begin
      Put_Line
        (Standard_Error,
         To_Wide_Wide_String
           (Template.Format
                (Image (File_Name (Location.File)),
                 Image (Location.Line),
                 Image (Location.Column),
                 Image (Message))));
   end Report_Warning;

end GNATdoc.Messages;
