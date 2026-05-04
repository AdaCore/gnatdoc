------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2025-2026, AdaCore                     --
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

   package Count_IO is
     new Ada.Wide_Wide_Text_IO.Integer_IO (Ada.Containers.Count_Type);

   package Line_Number_IO is
     new Ada.Wide_Wide_Text_IO.Modular_IO (Libadalang.Slocs.Line_Number);

   package Column_Number_IO is
     new Ada.Wide_Wide_Text_IO.Modular_IO (Libadalang.Slocs.Column_Number);

   package Kind_IO is
      new Ada.Wide_Wide_Text_IO.Enumeration_IO (Kinds);

   package Entity_Kind_IO is
      new Ada.Wide_Wide_Text_IO.Enumeration_IO (Entity_Kind);

   -----------
   -- Print --
   -----------

   procedure Print (Information : Line_Information_Array) is
      use Ada.Strings.Wide_Wide_Fixed;
      use Ada.Wide_Wide_Text_IO;

   begin
      for Line_Index in Information'Range loop
         declare
            Line : constant Line_Information := Information (Line_Index);

         begin
            Line_Number_IO.Put (Line_Index);

            --  Item information

            case Line.Item.Kind is
               when None =>
                  Put (16 * ' ');

               when others =>
                  Put (' ');
                  Kind_IO.Put (Line.Item.Kind);
                  Put (" :");
                  Count_IO.Put (Line.Item.Sections.Length);
            end case;

            --  Entity information

            case Line.Entity.Kind is
               when None =>
                  Put (12 * ' ');

               when others =>
                  Put (" |");
                  Entity_Kind_IO.Put (Line.Entity.Kind);
                  Put ('>');
                  Column_Number_IO.Put (Line.Entity.Indent);
            end case;

            --  Component group

            case Line.Component_Group.Kind is
               when None =>
                  Put (5 * ' ');

               when Cancel =>
                  Put (" | CN");

               when others =>
                  Put (" |:");
                  Count_IO.Put (Line.Component_Group.Sections.Length);
            end case;

            --  Entity group

            case Line.Entity_Group.Kind is
               when None =>
                  Put (' ');

               when others =>
                  Put (" |>");
                  Column_Number_IO.Put (Line.Entity_Group.Indent);
                  Put (" :");
                  Count_IO.Put (Line.Entity_Group.Sections.Length);
            end case;

            New_Line;
         end;
      end loop;
   end Print;

begin
   Line_Number_IO.Default_Width := 5;
   Column_Number_IO.Default_Width := 2;
   Kind_IO.Default_Width := 11;
   Entity_Kind_IO.Default_Width := 7;

   Count_IO.Default_Width := 2;
end GNATdoc.Comments.Extractor.Trailing.Debug;
