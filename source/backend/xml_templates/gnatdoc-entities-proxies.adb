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

with GNAT.SHA256;

with VSS.Strings.Conversions;
with VSS.XML.Templates.Proxies.Booleans;
with VSS.XML.Templates.Proxies.Strings;

with GNATdoc.Backend.ODF_Markup;
with GNATdoc.Comments.Helpers;
with GNATdoc.Comments.Proxies;
with GNATdoc.Proxies;

package body GNATdoc.Entities.Proxies is

   use type VSS.Strings.Virtual_String;

   type Entity_Reference_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy with
   record
      Entity : GNATdoc.Entities.Entity_Reference;
   end record;

   overriding function Component
     (Self : in out Entity_Reference_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   type TOC_Iterator is
     limited new VSS.XML.Templates.Proxies.Abstract_Proxy
       and VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator
   with record
      Entities : not null access GNATdoc.Entities.Entity_Information_Sets.Set;
      Position : GNATdoc.Entities.Entity_Information_Sets.Cursor;
      OOP_Mode : Boolean;
   end record;

   overriding function Next (Self : in out TOC_Iterator) return Boolean;

   overriding function Element
     (Self : in out TOC_Iterator)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   type Entity_Reference_Set_Proxy is
     new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with record
      Entities : not null access GNATdoc.Entities.Entity_Reference_Sets.Set;
      Nested   : aliased GNATdoc.Entities.Entity_Reference_Sets.Set;
      OOP_Mode : Boolean;
   end record;

   overriding function Iterator
     (Self : in out Entity_Reference_Set_Proxy)
      return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

   overriding function Is_Empty
     (Self : Entity_Reference_Set_Proxy) return Boolean;

   type Entity_Reference_Set_Iterator is
     limited new VSS.XML.Templates.Proxies.Abstract_Proxy
       and VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator
   with record
      Entities : not null access GNATdoc.Entities.Entity_Reference_Sets.Set;
      Position : GNATdoc.Entities.Entity_Reference_Sets.Cursor;
      OOP_Mode : Boolean;
   end record;

   overriding function Next
     (Self : in out Entity_Reference_Set_Iterator) return Boolean;

   overriding function Element
     (Self : in out Entity_Reference_Set_Iterator)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   function Digest
     (Item : GNATdoc.Entities.Entity_Signature)
      return VSS.Strings.Virtual_String;

   ---------------
   -- Component --
   ---------------

   overriding function Component
     (Self : in out Entity_Information_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      if Name = "all" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Nested'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "simple_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Simple_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "array_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Array_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "record_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Record_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "interface_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Interface_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "tagged_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Tagged_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "access_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Access_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "subtypes" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Subtypes'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "task_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Task_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "protected_types" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Protected_Types'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "constants" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Constants'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "variables" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Variables'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "subprograms" then
         if Self.OOP_Mode then
            return
              Entity_Reference_Set_Proxy'
                (Entities =>
                   Self.Entity.Belong_Subprograms'Unchecked_Access,
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);

         else
            return
              Entity_Information_Set_Proxy'
                (Entities => Self.Entity.Contain_Subprograms'Unchecked_Access,
                 OOP_Mode => Self.OOP_Mode);
         end if;

      elsif Name = "entries" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Entries'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "exceptions" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Exceptions'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "generic_instantiations" then
         return
           Entity_Information_Set_Proxy'
             (Entities =>
                Self.Entity.Generic_Instantiations'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "formals" then
         return
           Entity_Information_Set_Proxy'
             (Entities => Self.Entity.Formals'Unchecked_Access,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "declared_dispatching_subprograms" then
         return
           Entity_Reference_Set_Proxy'
             (Entities =>
                Self.Entity.Dispatching_Declared'Unchecked_Access,
              Nested   => <>,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "overrided_dispatching_subprograms" then
         return
           Entity_Reference_Set_Proxy'
             (Entities =>
                Self.Entity.Dispatching_Overrided'Unchecked_Access,
              Nested   => <>,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "inherited_dispatching_subprograms" then
         return
           Entity_Reference_Set_Proxy'
             (Entities =>
                Self.Entity.Dispatching_Inherited'Unchecked_Access,
              Nested   => <>,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "class_subprograms" then
         return Result : Entity_Reference_Set_Proxy :=
           (Entities =>
              Self.Entity.Dispatching_Inherited'Unchecked_Access,
            Nested   => <>,
            OOP_Mode => Self.OOP_Mode)
         do
            Result.Entities := Result.Nested'Unchecked_Access;
            Result.Nested.Union (Self.Entity.Dispatching_Declared);
            Result.Nested.Union (Self.Entity.Dispatching_Overrided);
            Result.Nested.Union (Self.Entity.Prefix_Callable_Declared);
         end return;

      elsif Name = "declared_prefix_callable_subprograms" then
         return
           Entity_Reference_Set_Proxy'
             (Entities =>
                Self.Entity.Prefix_Callable_Declared'Unchecked_Access,
              Nested   => <>,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "inherited_prefix_callable_subprograms" then
         return
           Entity_Reference_Set_Proxy'
             (Entities =>
                Self.Entity.Prefix_Callable_Inherited'Unchecked_Access,
              Nested   => <>,
              OOP_Mode => Self.OOP_Mode);

      elsif Name = "name" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => Self.Entity.Name);

      elsif Name = "qualified_name" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => Self.Entity.Qualified_Name);

      elsif Name = "code" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text =>
                GNATdoc.Comments.Helpers.Get_Ada_Code_Snippet
                  (Self.Entity.Documentation).Join_Lines (VSS.Strings.LF));

      elsif Name = "code_odf" then
         return
           GNATdoc.Proxies.Markup_Proxy'
             (Markup =>
                GNATdoc.Backend.ODF_Markup.Build_Code_Snipped_Markup
                  (GNATdoc.Comments.Helpers.Get_Ada_Code_Snippet
                     (Self.Entity.Documentation)));

      elsif Name = "documentation" then
         return
           GNATdoc.Comments.Proxies.Create
             (Self.Entity.Documentation'Unchecked_Access);

      elsif Name = "id" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => Digest (Self.Entity.Signature));

      elsif Name = "full_href" then
         if Self.Entity.Kind in Ada_Tagged_Type | Ada_Interface_Type
           and not Self.OOP_Mode
         then
            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Text =>
                   Digest (Self.Entity.Enclosing)
                 & ".html#"
                 & Digest (Self.Entity.Signature));

         elsif not Self.Entity.Belongs.Signature.Image.Is_Empty then
            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Text =>
                   Digest (Self.Entity.Belongs.Signature)
                 & ".html#"
                 & Digest (Self.Entity.Signature));
         end if;

         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => Digest (Self.Entity.Signature) & ".html");

      elsif Name = "local_href" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => "#" & Digest (Self.Entity.Signature));

      elsif Name = "is_documented" then
         return
           VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
             (Value => True);

      elsif Name = "is_interface_type" then
         return
           VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
             (Value => Self.Entity.Kind = Ada_Interface_Type);

      elsif Name = "is_tagged_type" then
         return
           VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
             (Value => Self.Entity.Kind = Ada_Tagged_Type);

      elsif Name = "is_method" then
         if Self.Entity.Kind in Ada_Function | Ada_Procedure then
            return
              VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
                (Value => Self.Entity.Is_Method);
         end if;

      elsif Name = "parent_type" then
         if GNATdoc.Entities.To_Entity.Contains
           (Self.Entity.Parent_Type.Signature)
         then
            return
              Entity_Information_Proxy'
                (Entity   =>
                   GNATdoc.Entities.To_Entity
                     (Self.Entity.Parent_Type.Signature),
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);

         elsif not Self.Entity.Parent_Type.Signature.Image.Is_Empty then
            return
              Entity_Reference_Proxy'(Entity => Self.Entity.Parent_Type);
         end if;

      elsif Name = "derived_types" then
         if not Self.Entity.Derived_Types.Is_Empty then
            return
              Entity_Reference_Set_Proxy'
                (Entities => Self.Entity.Derived_Types'Unchecked_Access,
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);
         end if;

      elsif Name = "progenitor_types" then
         if not Self.Entity.Progenitor_Types.Is_Empty then
            return
              Entity_Reference_Set_Proxy'
                (Entities => Self.Entity.Progenitor_Types'Unchecked_Access,
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);
         end if;

      elsif Name = "all_parent_types" then
         if not Self.Entity.All_Parent_Types.Is_Empty then
            return
              Entity_Reference_Set_Proxy'
                (Entities => Self.Entity.All_Parent_Types'Unchecked_Access,
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);
         end if;

      elsif Name = "all_progenitor_types" then
         if not Self.Entity.All_Progenitor_Types.Is_Empty then
            return
              Entity_Reference_Set_Proxy'
                (Entities =>
                   Self.Entity.All_Progenitor_Types'Unchecked_Access,
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);
         end if;

      elsif Name = "all_derived_types" then
         if not Self.Entity.All_Derived_Types.Is_Empty then
            return
              Entity_Reference_Set_Proxy'
                (Entities => Self.Entity.All_Derived_Types'Unchecked_Access,
                 Nested   => <>,
                 OOP_Mode => Self.OOP_Mode);
         end if;
      end if;

      return
        VSS.XML.Templates.Proxies.Error_Proxy'
          (Message => "unknown component '" & Name & "'");
   end Component;

   ---------------
   -- Component --
   ---------------

   overriding function Component
     (Self : in out Entity_Reference_Proxy;
      Name : VSS.Strings.Virtual_String)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      if Name = "is_documented" then
         return
           VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
             (Value => False);

      elsif Name = "name" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => Self.Entity.Qualified_Name.Split ('.').Last_Element);

      elsif Name = "qualified_name" then
         return
           VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
             (Text => Self.Entity.Qualified_Name);
      end if;

      return
        VSS.XML.Templates.Proxies.Error_Proxy'
          (Message => "unknown component '" & Name & "'");
   end Component;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self : in out TOC_Iterator)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      return
        Entity_Information_Proxy'
          (Entity   => Entity_Information_Sets.Element (Self.Position),
           Nested   => <>,
           OOP_Mode => Self.OOP_Mode);
   end Element;

   -------------
   -- Element --
   -------------

   overriding function Element
     (Self : in out Entity_Reference_Set_Iterator)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
   begin
      if GNATdoc.Entities.To_Entity.Contains
        (Entity_Reference_Sets.Element (Self.Position).Signature)
      then
         return
           Entity_Information_Proxy'
             (Entity   =>
                GNATdoc.Entities.To_Entity
                  (Entity_Reference_Sets.Element (Self.Position).Signature),
              Nested   => <>,
              OOP_Mode => Self.OOP_Mode);

      elsif not Entity_Reference_Sets.Element
        (Self.Position).Signature.Image.Is_Empty
      then
         return
           Entity_Reference_Proxy'
             (Entity => Entity_Reference_Sets.Element (Self.Position));

      else
         raise Program_Error;
      end if;
   end Element;

   ------------
   -- Digest --
   ------------

   function Digest
     (Item : GNATdoc.Entities.Entity_Signature)
      return VSS.Strings.Virtual_String is
   begin
      return
        VSS.Strings.Conversions.To_Virtual_String
          (GNAT.SHA256.Digest
             (VSS.Strings.Conversions.To_UTF_8_String (Item.Image)));
   end Digest;

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty
     (Self : Entity_Information_Set_Proxy) return Boolean is
   begin
      --  Given set might contains entities excluded from documentation
      --  (marked by `@private` tag), so ignore them.

      for Entity of Self.Entities.all loop
         if not GNATdoc.Backend.Is_Private_Entity (Entity) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Empty;

   --------------
   -- Is_Empty --
   --------------

   overriding function Is_Empty
     (Self : Entity_Reference_Set_Proxy) return Boolean is
   begin
      --  Given set might contains entities excluded from documentation
      --  (marked by `@private` tag), and entities comes from outside of
      --  the set of packages to be documented (for examples, entities that
      --  comes from generic instantiations, and that comes from RTL), so
      --  ignore them.

      for Entity of Self.Entities.all loop
         if To_Entity.Contains (Entity.Signature)
           and then not GNATdoc.Backend.Is_Private_Entity
                          (To_Entity (Entity.Signature))
         then
            return False;
         end if;
      end loop;

      return True;
   end Is_Empty;

   --------------
   -- Iterator --
   --------------

   overriding function Iterator
     (Self : in out Entity_Information_Set_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class is
   begin
      return
        TOC_Iterator'
          (Entities => Self.Entities,
           Position => <>,
           OOP_Mode => Self.OOP_Mode);
   end Iterator;

   --------------
   -- Iterator --
   --------------

   overriding function Iterator
     (Self : in out Entity_Reference_Set_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class is
   begin
      return
        Entity_Reference_Set_Iterator'
          (Entities => Self.Entities,
           Position => <>,
           OOP_Mode => Self.OOP_Mode);
   end Iterator;

   ----------
   -- Next --
   ----------

   overriding function Next (Self : in out TOC_Iterator) return Boolean is
   begin
      if Entity_Information_Sets.Has_Element (Self.Position) then
         Entity_Information_Sets.Next (Self.Position);

      else
         Self.Position :=
           Entity_Information_Sets.First (Self.Entities.all);
      end if;

      loop
         exit when not Entity_Information_Sets.Has_Element (Self.Position);

         exit when
           not GNATdoc.Backend.Is_Private_Entity
             (Entity_Information_Sets.Element (Self.Position));

         Entity_Information_Sets.Next (Self.Position);
      end loop;

      return Entity_Information_Sets.Has_Element (Self.Position);
   end Next;

   ----------
   -- Next --
   ----------

   overriding function Next
     (Self : in out Entity_Reference_Set_Iterator) return Boolean is
   begin
      if Entity_Reference_Sets.Has_Element (Self.Position) then
         Entity_Reference_Sets.Next (Self.Position);

      else
         Self.Position :=
           Entity_Reference_Sets.First (Self.Entities.all);
      end if;

      loop
         exit when not Entity_Reference_Sets.Has_Element (Self.Position);

         exit when
           To_Entity.Contains
             (Entity_Reference_Sets.Element (Self.Position).Signature)
             and then not GNATdoc.Backend.Is_Private_Entity
               (To_Entity
                  (Entity_Reference_Sets.Element
                     (Self.Position).Signature));

         Entity_Reference_Sets.Next (Self.Position);
      end loop;

      return Entity_Reference_Sets.Has_Element (Self.Position);
   end Next;

end GNATdoc.Entities.Proxies;
