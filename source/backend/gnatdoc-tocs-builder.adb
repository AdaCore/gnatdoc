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

   procedure Insert_Entity
     (Parent   : GNATdoc.TOCs.Content_Trees.Cursor;
      Entity   : not null GNATdoc.Entities.Entity_Information_Access;
      OOP      : Boolean;
      Position : out GNATdoc.TOCs.Content_Trees.Cursor);
   procedure Insert_Entity
     (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
      Entity : not null GNATdoc.Entities.Entity_Information_Access;
      OOP    : Boolean);
   --  Inserts `Entity` in the alphabetical order of their qualified names, but
   --  before any section children.

   ---------------
   -- Build_TOC --
   ---------------

   procedure Build_TOC (OOP : Boolean) is

      procedure Process_Compilation_Units
        (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
         Entity : not null GNATdoc.Entities.Entity_Information_Access);

      procedure Process_Tagged_Types
        (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
         Entity : not null GNATdoc.Entities.Entity_Information_Access);

      -------------------------------
      -- Process_Compilation_Units --
      -------------------------------

      procedure Process_Compilation_Units
        (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
         Entity : not null GNATdoc.Entities.Entity_Information_Access)
      is
         Position : GNATdoc.TOCs.Content_Trees.Cursor;

      begin
         if GNATdoc.Backend.Is_Excluded (Entity) then
            return;
         end if;

         Insert_Entity (Parent, Entity, OOP, Position);

         for Item of Entity.Packages loop
            Process_Compilation_Units (Position, Item);
         end loop;
      end Process_Compilation_Units;

      --------------------------
      -- Process_Tagged_Types --
      --------------------------

      procedure Process_Tagged_Types
        (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
         Entity : not null GNATdoc.Entities.Entity_Information_Access)
      is
         --  Position : GNATdoc.TOCs.Content_Trees.Cursor;

      begin
         if GNATdoc.Backend.Is_Excluded (Entity) then
            return;
         end if;

         for Item of Entity.Tagged_Types loop
            Insert_Entity (Parent, Item, OOP);
         end loop;

         for Item of Entity.Interface_Types loop
            Insert_Entity (Parent, Item, OOP);
         end loop;

         for Item of Entity.Packages loop
            Process_Tagged_Types (Parent, Item);
         end loop;
      end Process_Tagged_Types;

      Compilation_Units : GNATdoc.TOCs.Content_Trees.Cursor;
      Tagged_Types      : GNATdoc.TOCs.Content_Trees.Cursor;

   begin
      --  Build "Compilation Units" section

      TOC.Insert_Child
        (Parent   => TOC.Root,
         Before   => GNATdoc.TOCs.Content_Trees.No_Element,
         New_Item =>
           (Kind  => GNATdoc.TOCs.Section,
            Title => "Compilation Units",
            Id    => "compilation-units"),
         Position => Compilation_Units);

      for Item of GNATdoc.Entities.Compilation_Units.Packages loop
         Process_Compilation_Units (Compilation_Units, Item);
      end loop;

      --  Build "Tagged Types" section

      TOC.Insert_Child
        (Parent   => TOC.Root,
         Before   => GNATdoc.TOCs.Content_Trees.No_Element,
         New_Item =>
           (Kind  => GNATdoc.TOCs.Section,
            Title => "Tagged Types",
            Id    => "tagged-types"),
         Position => Tagged_Types);

      for Item of GNATdoc.Entities.Compilation_Units.Packages loop
         Process_Tagged_Types (Tagged_Types, Item);
      end loop;
   end Build_TOC;

   -------------------
   -- Insert_Entity --
   -------------------

   procedure Insert_Entity
     (Parent : GNATdoc.TOCs.Content_Trees.Cursor;
      Entity : not null GNATdoc.Entities.Entity_Information_Access;
      OOP    : Boolean)
   is
      Dummy : GNATdoc.TOCs.Content_Trees.Cursor;

   begin
      Insert_Entity (Parent, Entity, OOP, Dummy);
   end Insert_Entity;

   -------------------
   -- Insert_Entity --
   -------------------

   procedure Insert_Entity
     (Parent   : GNATdoc.TOCs.Content_Trees.Cursor;
      Entity   : not null GNATdoc.Entities.Entity_Information_Access;
      OOP      : Boolean;
      Position : out GNATdoc.TOCs.Content_Trees.Cursor)
   is
      use type VSS.Strings.Virtual_String;

      Current : GNATdoc.TOCs.Content_Trees.Cursor :=
        GNATdoc.TOCs.Content_Trees.First_Child (Parent);
      Next    : GNATdoc.TOCs.Content_Trees.Cursor;

   begin
      while GNATdoc.TOCs.Content_Trees.Has_Element (Current) loop
         Next  := GNATdoc.TOCs.Content_Trees.Next_Sibling (Current);

         if TOC (Current).Kind = Section then
            exit;

         elsif TOC (Current).Entity.Qualified_Name < Entity.Qualified_Name
           and (GNATdoc.TOCs.Content_Trees.Has_Element (Next)
                and then TOC (Next).Kind = GNATdoc.TOCs.Entity
                and then Entity.Qualified_Name
                           < TOC (Next).Entity.Qualified_Name)
         then
            exit;
         end if;

         Current := Next;
      end loop;

      TOC.Insert_Child
        (Parent   => Parent,
         Before   => Current,
         New_Item =>
           (Kind       => GNATdoc.TOCs.Entity,
            Entity     => Entity.Reference,
            Local_Href =>
              GNATdoc.Entities.Proxies.Local_Href (Entity.all, OOP),
            Full_Href  =>
              GNATdoc.Entities.Proxies.Full_Href (Entity.all, OOP)),
         Position => Position);
   end Insert_Entity;

end GNATdoc.TOCs.Builder;
