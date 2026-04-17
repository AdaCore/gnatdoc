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

with VSS.XML.Templates.Proxies.Strings;

package body GNATdoc.TOCs.Proxies is

   type Tree_Iterator is
     limited new VSS.XML.Templates.Proxies.Abstract_Proxy
       and VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator
   with record
      Parent  : GNATdoc.TOCs.Content_Trees.Cursor;
      Current : GNATdoc.TOCs.Content_Trees.Cursor;
   end record;

   overriding function Next (Self : in out Tree_Iterator) return Boolean;

   overriding function Element
     (Self : in out Tree_Iterator)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   type Content_Entry_Sequence_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy
   with record
      Parent : GNATdoc.TOCs.Content_Trees.Cursor;
   end record;

   overriding function Iterator
     (Self : in out Content_Entry_Sequence_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

   overriding function Is_Empty
     (Self : Content_Entry_Sequence_Proxy) return Boolean;

   type Content_Entry_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy with
   record
      Position : GNATdoc.TOCs.Content_Trees.Cursor;
   end record;

   overriding function Component
     (Self : in out Content_Entry_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   ---------------
   -- Component --
   ---------------

   overriding function Component
     (Self : in out Content_Entry_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class
   is
      use type VSS.Strings.Virtual_String;

      Item : constant Content_Entry := TOC.Reference (Self.Position);

   begin
      if Name = "full_href" then
         case Item.Kind is
            when Section =>
               return
                 VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                   (Text => VSS.Strings.Empty_Virtual_String);

            when Entity =>
               return
                 VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                   (Text => Item.Full_Href);
         end case;

      elsif Name = "id" then
         case Item.Kind is
            when Section =>
               return
                 VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                   (Text => Item.Id);

            when Entity =>
               null;
         end case;

      elsif Name = "sections" then
         return Content_Entry_Sequence_Proxy'(Parent => Self.Position);

      elsif Name = "title" then
         case Item.Kind is
            when Section =>
               return
                 VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                   (Text => Item.Title);

            when Entity =>
               return
                 VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                   (Text => Item.Entity.Qualified_Name);
         end case;
      end if;

      return
        VSS.XML.Templates.Proxies.Error_Proxy'
          (Message => "unknown component '" & Name & "'");
   end Component;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self : in out Tree_Iterator)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      return Content_Entry_Proxy'(Position => Self.Current);
   end Element;

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty
     (Self : Content_Entry_Sequence_Proxy) return Boolean is
   begin
      return GNATdoc.TOCs.Content_Trees.Is_Leaf (Self.Parent);
   end Is_Empty;

   --------------
   -- Iterator --
   --------------

   overriding function Iterator
     (Self : in out Content_Entry_Sequence_Proxy)
      return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class is
   begin
      return
        Tree_Iterator'
          (Parent  => Self.Parent,
           Current => GNATdoc.TOCs.Content_Trees.No_Element);
   end Iterator;

   ----------
   -- Next --
   ----------

   overriding function Next (Self : in out Tree_Iterator) return Boolean is
      use type GNATdoc.TOCs.Content_Trees.Cursor;

   begin
      Self.Current :=
        (if Self.Current = GNATdoc.TOCs.Content_Trees.No_Element
         then GNATdoc.TOCs.Content_Trees.First_Child (Self.Parent)
         else GNATdoc.TOCs.Content_Trees.Next_Sibling (Self.Current));

      return Self.Current /= GNATdoc.TOCs.Content_Trees.No_Element;
   end Next;

   ---------------
   -- TOC_Proxy --
   ---------------

   function TOC_Proxy return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      return Content_Entry_Sequence_Proxy'(Parent => TOC.Root);
   end TOC_Proxy;

end GNATdoc.TOCs.Proxies;
