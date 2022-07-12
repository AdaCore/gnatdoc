------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2022, AdaCore                        --
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

package body GNATdoc.Comments.Proxies is

   use type VSS.Strings.Virtual_String;

   package Section_Vectors is
     new Ada.Containers.Vectors (Positive, Section_Access);

   type Section_Sequence_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with
   record
      Sections : Section_Vectors.Vector;
   end record;

   overriding function Iterator
     (Self : in out Section_Sequence_Proxy)
      return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

   overriding function Is_Empty
     (Self : Section_Sequence_Proxy) return Boolean;

   type Section_Sequence_Iterator_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator with
   record
      Sections : Section_Vectors.Vector;
      Position : Section_Vectors.Cursor;
   end record;

   overriding function Next
     (Self : in out Section_Sequence_Iterator_Proxy) return Boolean;

   overriding function Element
     (Self : in out Section_Sequence_Iterator_Proxy)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   type Section_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy with
   record
      Section : Section_Access;
   end record;

   overriding function Component
     (Self : in out Section_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   ---------------
   -- Component --
   ---------------

   overriding function Component
     (Self : in out Structured_Comment_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class
   is

      function Filter
        (Kind : Section_Kind)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

      ------------
      -- Filter --
      ------------

      function Filter
        (Kind : Section_Kind)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class
      is
         Sections : Section_Vectors.Vector;

      begin
         for Section of Self.Documentation.Sections loop
            if Section.Kind = Kind then
               Sections.Append (Section);
            end if;
         end loop;

         return Section_Sequence_Proxy'(Sections => Sections);
      end Filter;

   begin
      if Name = "description" then
         declare
            Text : VSS.String_Vectors.Virtual_String_Vector;

         begin
            for Section of Self.Documentation.Sections loop
               if Section.Kind = Description then
                  Text := Section.Text;
               end if;
            end loop;

            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Content => Text.Join_Lines (VSS.Strings.LF));
         end;

      elsif Name = "enumeration_literals" then
         return Filter (Enumeration_Literal);

      elsif Name = "exceptions" then
         return Filter (Raised_Exception);

      elsif Name = "fields" then
         return Filter (Field);

      elsif Name = "formals" then
         return Filter (Formal);

      elsif Name = "parameters" then
         return Filter (Parameter);

      elsif Name = "returns" then
         --  There is only single item can be here, so it may be returned
         --  or error reported, however, necessary expression is not
         --  supported by templates engine.

         return Filter (Returns);

      else
         return
           VSS.XML.Templates.Proxies.Error_Proxy'
             (Message => "unknown component '" & Name & "'");
      end if;
   end Component;

   ---------------
   -- Component --
   ---------------

   overriding function Component
     (Self : in out Section_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      if Name = "name" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Content => Self.Section.Name);

      elsif Name = "description" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Content => Self.Section.Text.Join_Lines (VSS.Strings.LF));

      else
         return
           VSS.XML.Templates.Proxies.Error_Proxy'
             (Message => "unknown component '" & Name & "'");
      end if;
   end Component;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self : in out Section_Sequence_Iterator_Proxy)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      return
        Section_Proxy'(Section => Section_Vectors.Element (Self.Position));
   end Element;

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty
     (Self : Section_Sequence_Proxy) return Boolean is
   begin
      return Self.Sections.Is_Empty;
   end Is_Empty;

   --------------
   -- Iterator --
   --------------

   overriding function Iterator
     (Self : in out Section_Sequence_Proxy)
      return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class is
   begin
      return
        Section_Sequence_Iterator_Proxy'
          (Sections => Self.Sections,
           Position => <>);
   end Iterator;

   ----------
   -- Next --
   ----------

   overriding function Next
     (Self : in out Section_Sequence_Iterator_Proxy) return Boolean is
   begin
      if Section_Vectors.Has_Element (Self.Position) then
         Section_Vectors.Next (Self.Position);

      else
         Self.Position := Self.Sections.First;
      end if;

      return Section_Vectors.Has_Element (Self.Position);
   end Next;

end GNATdoc.Comments.Proxies;
