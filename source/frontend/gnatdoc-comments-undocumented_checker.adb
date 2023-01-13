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

with GNATdoc.Messages;

package body GNATdoc.Comments.Undocumented_Checker is

   ------------------------
   -- Check_Undocumented --
   ------------------------

   procedure Check_Undocumented
     (Location      : GNATdoc.Entities.Entity_Location;
      Name          : VSS.Strings.Virtual_String;
      Documentation : GNATdoc.Comments.Structured_Comment)
   is
      use type VSS.Strings.Virtual_String;

   begin
      for Section of Documentation.Sections loop
         if Section.Kind in Description then
            if Section.Text.Is_Empty then
               GNATdoc.Messages.Report_Warning
                 (Location, "entity " & Name & " is not documented");
            end if;

            exit;
         end if;
      end loop;

      for Section of Documentation.Sections loop
         if Section.Kind in Component
           and then Section.Text.Is_Empty
         then
            GNATdoc.Messages.Report_Warning
              (Location,
               VSS.Strings.To_Virtual_String
                 (case Section.Kind is
                     when Formal              => "generic formal",
                     when Enumeration_Literal => "enumeration literal",
                     when Field               => "component",
                     when Parameter           => "parameter",
                     when Returns             => "return value",
                     when Raised_Exception    => "raised exception",
                     when others              => raise Program_Error)
               & (if Section.Kind /= Returns
                    then " " & Section.Name else "")
               & VSS.Strings.To_Virtual_String (" is not documented"));
         end if;
      end loop;
   end Check_Undocumented;

end GNATdoc.Comments.Undocumented_Checker;
