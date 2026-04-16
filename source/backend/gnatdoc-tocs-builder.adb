------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2026, AdaCore                        --
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

with GNATdoc.Backend;
with GNATdoc.Entities.Proxies;

package body GNATdoc.TOCs.Builder is

   ---------------
   -- Build_TOC --
   ---------------

   procedure Build_TOC (OOP : Boolean) is

      procedure Process
        (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
         Entity : not null GNATdoc.Entities.Entity_Information_Access);

      -------------
      -- Process --
      -------------

      procedure Process
        (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
         Entity : not null GNATdoc.Entities.Entity_Information_Access)
      is
         Position : GNATdoc.TOCs.Content_Trees.Cursor;

      begin
         if GNATdoc.Backend.Is_Private_Entity (Entity) then
            return;
         end if;

         TOC.Insert_Child
           (Parent   => Parent,
            Before   => GNATdoc.TOCs.Content_Trees.No_Element,
            New_Item =>
              (Kind       => GNATdoc.TOCs.Entity,
               Entity     => Entity.Reference,
               Local_Href =>
                 GNATdoc.Entities.Proxies.Local_Href (Entity.all, OOP),
               Full_Href  =>
                 GNATdoc.Entities.Proxies.Full_Href (Entity.all, OOP)),
            Position => Position);

         for Item of Entity.Packages loop
            Process (Position, Item);
         end loop;
      end Process;

      Compilation_Units : GNATdoc.TOCs.Content_Trees.Cursor;

   begin
      TOC.Insert_Child
        (Parent   => TOC.Root,
         Before   => GNATdoc.TOCs.Content_Trees.No_Element,
         New_Item =>
           (Kind  => GNATdoc.TOCs.Section,
            Title => "Compilation Units",
            Id    => "compilation-units"),
         Position => Compilation_Units);

      for Item of GNATdoc.Entities.Compilation_Units.Packages loop
         Process (Compilation_Units, Item);
      end loop;
   end Build_TOC;

end GNATdoc.TOCs.Builder;
