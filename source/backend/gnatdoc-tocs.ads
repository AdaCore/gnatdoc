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

with Ada.Containers.Indefinite_Multiway_Trees;

with GNATdoc.Entities;

package GNATdoc.TOCs is

   type Entry_Kind is (Section, Entity);

   type Content_Entry (Kind : Entry_Kind) is tagged record
      case Kind is
         when Section =>
            Title : VSS.Strings.Virtual_String;
            Id    : VSS.Strings.Virtual_String;

         when Entity =>
            Entity     : GNATdoc.Entities.Entity_Reference;
            Local_Href : VSS.Strings.Virtual_String;
            Full_Href  : VSS.Strings.Virtual_String;
      end case;
   end record;

   package Content_Trees is
     new Ada.Containers.Indefinite_Multiway_Trees
       (Element_Type => Content_Entry);

   TOC : Content_Trees.Tree;

end GNATdoc.TOCs;
