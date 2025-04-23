------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2025, AdaCore                     --
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

with VSS.XML.Templates.Proxies;

package GNATdoc.Entities.Proxies is

   type Entity_Information_Set_Proxy is limited
     new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with record
      Entities : not null access GNATdoc.Entities.Entity_Information_Sets.Set;
      OOP_Mode : Boolean;
   end record;

   overriding function Iterator
     (Self : in out Entity_Information_Set_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

   overriding function Is_Empty
     (Self : Entity_Information_Set_Proxy) return Boolean;

   type Entity_Information_Proxy is limited
     new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy
   with record
      Entity   : GNATdoc.Entities.Entity_Information_Access;
      Nested   : aliased GNATdoc.Entities.Entity_Information_Sets.Set;
      OOP_Mode : Boolean;
   end record;

   overriding function Component
     (Self : in out Entity_Information_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

end GNATdoc.Entities.Proxies;
