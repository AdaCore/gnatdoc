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

with Ada.Strings.Wide_Wide_Fixed;
with Ada.Wide_Wide_Text_IO;

package body GNATdoc.Comments.Extractor.Trailing.Debug is

   package Line_Number_IO is
     new Ada.Wide_Wide_Text_IO.Modular_IO (Libadalang.Slocs.Line_Number);

   package Kind_IO is
      new Ada.Wide_Wide_Text_IO.Enumeration_IO (Kinds);

   -----------
   -- Print --
   -----------

   procedure Print (Information : Line_Information_Array) is
      use Ada.Strings.Wide_Wide_Fixed;
      use Ada.Wide_Wide_Text_IO;

   begin
      for Line_Index in Information'Range loop
         Line_Number_IO.Put (Line_Index, Width => 5);

         --  Item information

         case Information (Line_Index).Item.Kind is
            when None =>
               Put (12 * ' ');

            when others =>
               Put (' ');
               Kind_IO.Put (Information (Line_Index).Item.Kind, Width => 11);
         end case;

         New_Line;
      end loop;
   end Print;

end GNATdoc.Comments.Extractor.Trailing.Debug;
