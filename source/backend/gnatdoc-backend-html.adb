------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2023, AdaCore                     --
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

pragma Warnings (Off);
pragma Ada_2020;
pragma Ada_2022;
pragma Warnings (On);

with GNAT.SHA256;
with GNATCOLL.VFS;

with Input_Sources.File;

with VSS.HTML.Writers;
with VSS.Strings.Conversions;
with VSS.String_Vectors;
with VSS.XML.Templates.Processors;
with VSS.XML.Templates.Proxies.Booleans;
with VSS.XML.Templates.Proxies.Strings;
with VSS.XML.XmlAda_Readers;

with GNATdoc.Comments.Helpers;
with GNATdoc.Comments.Proxies;
with GNATdoc.Configuration;
with GNATdoc.Entities;
with Streams;

package body GNATdoc.Backend.HTML is

   use GNAT.SHA256;
   use GNATCOLL.VFS;
   use GNATdoc.Entities;
   use VSS.Strings.Conversions;

   procedure Generate_Unit_Documentation_Page
     (Self   : in out HTML_Backend'Class;
      Entity : not null Entity_Information_Access);
   --  Generate unit-style documentation page for given entity.

   procedure Generate_Class_Documentation_Page
     (Self   : in out HTML_Backend'Class;
      Entity : not null Entity_Information_Access);
   --  Generate class-style documentation page for given entity.

   package Proxies is

      type Entity_Information_Set_Proxy is limited
        new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with record
         Entities  : not null access Entity_Information_Sets.Set;
         Container : aliased Entity_Information_Sets.Set;
         OOP_Mode  : Boolean;
      end record;

      overriding function Iterator
        (Self : in out Entity_Information_Set_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

      overriding function Is_Empty
        (Self : Entity_Information_Set_Proxy) return Boolean;

      type Entity_Information_Proxy is limited
        new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy
      with record
         Entity   : Entity_Information_Access;
         Nested   : aliased Entity_Information_Sets.Set;
         OOP_Mode : Boolean;
      end record;

      overriding function Component
        (Self : in out Entity_Information_Proxy;
         Name : VSS.Strings.Virtual_String)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

   end Proxies;

   -------------
   -- Proxies --
   -------------

   package body Proxies is

      use type VSS.Strings.Virtual_String;

      type Entity_Reference_Proxy is
        limited new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy with
      record
         Entity : Entity_Reference;
      end record;

      overriding function Component
        (Self : in out Entity_Reference_Proxy;
         Name : VSS.Strings.Virtual_String)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

      type TOC_Iterator is
        limited new VSS.XML.Templates.Proxies.Abstract_Proxy
          and VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator
      with record
         Entities : not null access Entity_Information_Sets.Set;
         Position : Entity_Information_Sets.Cursor;
         OOP_Mode : Boolean;
      end record;

      overriding function Next (Self : in out TOC_Iterator) return Boolean;

      overriding function Element
        (Self : in out TOC_Iterator)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

      type Entity_Reference_Set_Proxy is
        new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with record
         Entities : not null access Entity_Reference_Sets.Set;
         Nested   : aliased Entity_Reference_Sets.Set;
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
         Entities : not null access Entity_Reference_Sets.Set;
         Position : Entity_Reference_Sets.Cursor;
         OOP_Mode : Boolean;
      end record;

      overriding function Next
        (Self : in out Entity_Reference_Set_Iterator) return Boolean;

      overriding function Element
        (Self : in out Entity_Reference_Set_Iterator)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

      function Digest
        (Item : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String;

      ---------------
      -- Component --
      ---------------

      overriding function Component
        (Self : in out Entity_Information_Proxy;
         Name : VSS.Strings.Virtual_String)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
      begin
         if Name = "all" then
            return Result : Entity_Information_Set_Proxy :=
              (Entities  => Self.Nested'Unchecked_Access,
               Container => <>,
               OOP_Mode  => Self.OOP_Mode)
            do
               if Self.OOP_Mode then
                  Result.Entities := Result.Container'Unchecked_Access;

                  for Item of Self.Nested loop
                     if (Item.Kind not in Ada_Function | Ada_Procedure
                           or not Item.Is_Method)
                       and Item.Kind
                             not in Ada_Tagged_Type | Ada_Interface_Type
                     then
                        Result.Container.Insert (Item);
                     end if;
                  end loop;
               end if;
            end return;

         elsif Name = "simple_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Simple_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "array_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Array_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "record_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Record_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "interface_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Interface_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "tagged_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Tagged_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "access_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Access_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "subtypes" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Subtypes'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "task_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Task_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "protected_types" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Protected_Types'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "constants" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Constants'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "variables" then
            return
              Entity_Information_Set_Proxy'
                (Entities  => Self.Entity.Variables'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "subprograms" then
            return Result : Entity_Information_Set_Proxy :=
              (Entities  => Self.Entity.Subprograms'Unchecked_Access,
               Container => <>,
               OOP_Mode  => Self.OOP_Mode)
            do
               if Self.OOP_Mode then
                  --  Rebuild list of subprograms by remove of methods.

                  Result.Entities := Result.Container'Unchecked_Access;

                  for Item of Self.Entity.Subprograms loop
                     if not Item.Is_Method then
                        Result.Container.Insert (Item);
                     end if;
                  end loop;
               end if;
            end return;

         elsif Name = "entries" then
            return
              Entity_Information_Set_Proxy'
                (Entities => Self.Entity.Entries'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "exceptions" then
            return
              Entity_Information_Set_Proxy'
                (Entities => Self.Entity.Exceptions'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "generic_instantiations" then
            return
              Entity_Information_Set_Proxy'
                (Entities =>
                   Self.Entity.Generic_Instantiations'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

         elsif Name = "formals" then
            return
              Entity_Information_Set_Proxy'
                (Entities => Self.Entity.Formals'Unchecked_Access,
                 Container => <>,
                 OOP_Mode  => Self.OOP_Mode);

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
               Result.Nested.Union (Self.Entity.Non_Dispatching_Declared);
            end return;

         elsif Name = "declared_non_dispatching_subprograms" then
            return
              Entity_Reference_Set_Proxy'
                (Entities =>
                   Self.Entity.Non_Dispatching_Declared'Unchecked_Access,
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

         elsif Name = "documentation" then
            return
              GNATdoc.Comments.Proxies.Create
                (Self.Entity.Documentation'Unchecked_Access);

         elsif Name = "id" then
            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Text => Digest (Self.Entity.Signature));

         elsif Name = "full_href" then
            if not Self.OOP_Mode then
               raise Program_Error;
            end if;

            if Self.Entity.Kind in Ada_Tagged_Type | Ada_Interface_Type
              and not Self.OOP_Mode
            then
               return
                 VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                   (Text =>
                      Digest (Self.Entity.Enclosing)
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

            elsif not Self.Entity.Parent_Type.Signature.Is_Empty then
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
                     (Self.Position).Signature.Is_Empty
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
        (Item : VSS.Strings.Virtual_String)
         return VSS.Strings.Virtual_String is
      begin
         return To_Virtual_String (Digest (To_UTF_8_String (Item)));
      end Digest;

      --------------
      -- Is_Empty --
      --------------

      overriding function Is_Empty
        (Self : Entity_Information_Set_Proxy) return Boolean is
      begin
         return Self.Entities.Is_Empty;
      end Is_Empty;

      --------------
      -- Is_Empty --
      --------------

      overriding function Is_Empty
        (Self : Entity_Reference_Set_Proxy) return Boolean is
      begin
         return Self.Entities.Is_Empty;
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

         return Entity_Reference_Sets.Has_Element (Self.Position);
      end Next;

   end Proxies;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out HTML_Backend) is
      Index_Entities       : aliased Entity_Information_Sets.Set;
      Non_Index_Entities   : aliased Entity_Information_Sets.Set;
      Class_Index_Entities : aliased Entity_Information_Sets.Set;

   begin
      for Item of Globals.Packages loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Subprograms loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Package_Renamings loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Generic_Instantiations loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Task_Types loop
         if not Is_Private_Entity (Item) then
            Non_Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Protected_Types loop
         if not Is_Private_Entity (Item) then
            Non_Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Interface_Types loop
         if not Is_Private_Entity (Item) then
            Class_Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Tagged_Types loop
         if not Is_Private_Entity (Item) then
            Class_Index_Entities.Insert (Item);
         end if;
      end loop;

      declare
         Input  : Input_Sources.File.File_Input;
         Reader : VSS.XML.XmlAda_Readers.XmlAda_Reader;
         Filter : aliased VSS.XML.Templates.Processors.XML_Template_Processor;
         Writer : aliased VSS.HTML.Writers.HTML5_Writer;
         Output : aliased Streams.Output_Text_Stream;
         Path   : VSS.String_Vectors.Virtual_String_Vector;

      begin
         --  Open input and output files.

         Path.Clear;
         Path.Append ("template");
         Path.Append ("index.xhtml");
         Input_Sources.File.Open
           (String (Self.Lookup_Resource_File (Path).Full_Name.all),
            Input);
         Output.Open
           (GNATCOLL.VFS.Create_From_Dir (Self.Output_Root, "index.html"));

         --  Connect components

         Writer.Set_Output_Stream (Output'Unchecked_Access);
         Filter.Set_Content_Handler (Writer'Unchecked_Access);
         Reader.Set_Content_Handler (Filter'Unchecked_Access);

         --  Bind information

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("toc");
         Filter.Bind
           (Path,
            new Proxies.Entity_Information_Set_Proxy'
              (Entities  => Index_Entities'Unchecked_Access,
               Container => <>,
               OOP_Mode  => Self.OOP_Mode));

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("classes_toc");
         Filter.Bind
           (Path,
            new Proxies.Entity_Information_Set_Proxy'
              (Entities  => Class_Index_Entities'Unchecked_Access,
               Container => <>,
               OOP_Mode  => Self.OOP_Mode));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;

      for Item of Index_Entities loop
         Self.Generate_Unit_Documentation_Page (Item);
      end loop;

      for Item of Non_Index_Entities loop
         Self.Generate_Unit_Documentation_Page (Item);
      end loop;

      if Self.OOP_Mode then
         for Item of Class_Index_Entities loop
            Self.Generate_Class_Documentation_Page (Item);
         end loop;
      end if;
   end Generate;

   ---------------------------------------
   -- Generate_Class_Documentation_Page --
   ---------------------------------------

   procedure Generate_Class_Documentation_Page
     (Self   : in out HTML_Backend'Class;
      Entity : not null Entity_Information_Access)
   is
      Name : constant String :=
        Digest (To_UTF_8_String (Entity.Signature)) & ".html";

   begin
      declare
         Input  : Input_Sources.File.File_Input;
         Reader : VSS.XML.XmlAda_Readers.XmlAda_Reader;
         Filter : aliased VSS.XML.Templates.Processors.XML_Template_Processor;
         Writer : aliased VSS.HTML.Writers.HTML5_Writer;
         Output : aliased Streams.Output_Text_Stream;
         Nested : Entity_Information_Sets.Set;
         Path   : VSS.String_Vectors.Virtual_String_Vector;

      begin
         Nested.Union (Entity.Formals);
         Nested.Union (Entity.Exceptions);
         Nested.Union (Entity.Simple_Types);
         Nested.Union (Entity.Array_Types);
         Nested.Union (Entity.Record_Types);
         Nested.Union (Entity.Interface_Types);
         Nested.Union (Entity.Tagged_Types);
         Nested.Union (Entity.Access_Types);
         Nested.Union (Entity.Subtypes);
         Nested.Union (Entity.Constants);
         Nested.Union (Entity.Variables);
         Nested.Union (Entity.Subprograms);
         Nested.Union (Entity.Entries);
         Nested.Union (Entity.Generic_Instantiations);

         --  Open input and output files.

         Path.Clear;
         Path.Append ("template");
         Path.Append ("class.xhtml");
         Input_Sources.File.Open
           (String (Self.Lookup_Resource_File (Path).Full_Name.all),
            Input);
         Output.Open
           (GNATCOLL.VFS.Create_From_Dir
              (Self.Output_Root, Filesystem_String (Name)));

         --  Connect components

         Writer.Set_Output_Stream (Output'Unchecked_Access);
         Filter.Set_Content_Handler (Writer'Unchecked_Access);
         Reader.Set_Content_Handler (Filter'Unchecked_Access);

         --  Bind information

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("entity");
         Filter.Bind
           (Path,
            new Proxies.Entity_Information_Proxy'
              (Entity   => Entity,
               Nested   => Nested,
               OOP_Mode => Self.OOP_Mode));

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("oop_mode");
         Filter.Bind
           (Path,
            new VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
              (Value => Self.OOP_Mode));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;
   end Generate_Class_Documentation_Page;

   --------------------------------------
   -- Generate_Unit_Documentation_Page --
   --------------------------------------

   procedure Generate_Unit_Documentation_Page
     (Self   : in out HTML_Backend'Class;
      Entity : not null Entity_Information_Access)
   is
      Name : constant String :=
        Digest (To_UTF_8_String (Entity.Signature)) & ".html";

   begin
      declare
         Input  : Input_Sources.File.File_Input;
         Reader : VSS.XML.XmlAda_Readers.XmlAda_Reader;
         Filter : aliased VSS.XML.Templates.Processors.XML_Template_Processor;
         Writer : aliased VSS.HTML.Writers.HTML5_Writer;
         Output : aliased Streams.Output_Text_Stream;
         Nested : Entity_Information_Sets.Set;
         Path   : VSS.String_Vectors.Virtual_String_Vector;

      begin
         Nested.Union (Entity.Formals);
         Nested.Union (Entity.Exceptions);
         Nested.Union (Entity.Simple_Types);
         Nested.Union (Entity.Array_Types);
         Nested.Union (Entity.Record_Types);
         Nested.Union (Entity.Interface_Types);
         Nested.Union (Entity.Tagged_Types);
         Nested.Union (Entity.Access_Types);
         Nested.Union (Entity.Subtypes);
         Nested.Union (Entity.Constants);
         Nested.Union (Entity.Variables);
         Nested.Union (Entity.Subprograms);
         Nested.Union (Entity.Entries);
         Nested.Union (Entity.Generic_Instantiations);

         --  Open input and output files.

         Path.Clear;
         Path.Append ("template");
         Path.Append ("unit.xhtml");
         Input_Sources.File.Open
           (String (Self.Lookup_Resource_File (Path).Full_Name.all),
            Input);
         Output.Open
           (GNATCOLL.VFS.Create_From_Dir
              (Self.Output_Root, Filesystem_String (Name)));

         --  Connect components

         Writer.Set_Output_Stream (Output'Unchecked_Access);
         Filter.Set_Content_Handler (Writer'Unchecked_Access);
         Reader.Set_Content_Handler (Filter'Unchecked_Access);

         --  Bind information

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("entity");
         Filter.Bind
           (Path,
            new Proxies.Entity_Information_Proxy'
              (Entity   => Entity,
               Nested   => Nested,
               OOP_Mode => Self.OOP_Mode));

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("oop_mode");
         Filter.Bind
           (Path,
            new VSS.XML.Templates.Proxies.Booleans.Boolean_Proxy'
              (Value => Self.OOP_Mode));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;
   end Generate_Unit_Documentation_Page;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out HTML_Backend) is

      procedure Copy_Static (Root : GNATCOLL.VFS.Virtual_File);

      -----------------
      -- Copy_Static --
      -----------------

      procedure Copy_Static (Root : GNATCOLL.VFS.Virtual_File) is
         Source  : GNATCOLL.VFS.Virtual_File;
         Success : Boolean;

      begin
         if Root /= GNATCOLL.VFS.No_File then
            Source := Root / "static";
            Source.Copy (Self.Output_Root.Full_Name.all, Success);
         end if;
      end Copy_Static;

   begin
      Abstract_Backend (Self).Initialize;

      Self.OOP_Mode :=
        GNATdoc.Configuration.Provider.Backend_Options.Contains ("oop");

      Copy_Static (Self.System_Resources_Root);
      Copy_Static (Self.Project_Resources_Root);
   end Initialize;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out HTML_Backend) return VSS.Strings.Virtual_String is
   begin
      return "html";
   end Name;

end GNATdoc.Backend.HTML;
