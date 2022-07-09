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

pragma Warnings (Off);
pragma Ada_2020;
pragma Ada_2022;
pragma Warnings (On);

with GNAT.SHA256;
with GNATCOLL.VFS;

with Input_Sources.File;

with GNATdoc.Comments.Helpers;
with GNATdoc.Entities;
with GNATdoc.Options;

with VSS.HTML.Writers;
with VSS.Strings.Conversions;
with VSS.String_Vectors;
with VSS.XML.Templates.Processors;
with VSS.XML.Templates.Proxies;
with VSS.XML.Templates.Values;
with VSS.XML.XmlAda_Readers;

with Streams;

package body GNATdoc.Backend is

   use GNAT.SHA256;
   use GNATCOLL.VFS;
   use GNATdoc.Comments.Helpers;
   use GNATdoc.Entities;
   use VSS.Strings.Conversions;

   procedure Generate_Entity_Documentation_Page
     (Entity : not null Entity_Information_Access);

   function Is_Private_Entity
     (Entity : not null Entity_Information_Access) return Boolean;
   --  Return True when given entity is private package, or explicitly marked
   --  as private entity, or enclosed by the private package, or enclosed by
   --  the entity marked as private entity.

   package Proxies is

      type Entity_Information_Set_Proxy is limited
        new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with record
         Index_Entities : not null access Entity_Information_Sets.Set;
      end record;

      overriding function Iterator
        (Self : in out Entity_Information_Set_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

      overriding function Is_Empty
        (Self : Entity_Information_Set_Proxy) return Boolean;

      type Entity_Information_Proxy is limited
        new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy
      with record
         Entity : Entity_Information_Access;
         Nested : aliased Entity_Information_Sets.Set;
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

      use type VSS.String_Vectors.Virtual_String_Vector;
      use type VSS.Strings.Virtual_String;

      type Entity_Information_Set_Proxy_Access is
        access all Entity_Information_Set_Proxy;

      type TOC_Iterator is
      limited new VSS.XML.Templates.Proxies.Abstract_Proxy
        and VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator
        and VSS.XML.Templates.Proxies.Abstract_Value_Proxy
      with record
         Entities : not null access Entity_Information_Sets.Set;
         Position : Entity_Information_Sets.Cursor;
      end record;

      overriding function Next (Self : in out TOC_Iterator) return Boolean;

      overriding function Element
        (Self : in out TOC_Iterator)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

      overriding function Value
        (Self : TOC_Iterator;
         Path : VSS.String_Vectors.Virtual_String_Vector)
         return VSS.XML.Templates.Values.Value;

      function Digest
        (Item : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String;

      type String_Proxy is
        limited new VSS.XML.Templates.Proxies.Abstract_Content_Proxy with
      record
         Content : VSS.Strings.Virtual_String;
      end record;

      overriding function Content
        (Self : String_Proxy) return VSS.Strings.Virtual_String;

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
                (Index_Entities => Self.Nested'Unchecked_Access);

         elsif Name = "simple_types" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Simple_Types'Unchecked_Access);

         elsif Name = "array_types" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Array_Types'Unchecked_Access);

         elsif Name = "record_types" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Record_Types'Unchecked_Access);

         elsif Name = "interface_types" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities =>
                   Self.Entity.Interface_Types'Unchecked_Access);

         elsif Name = "tagged_types" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Tagged_Types'Unchecked_Access);

         elsif Name = "access_types" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Access_Types'Unchecked_Access);

         elsif Name = "subtypes" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Subtypes'Unchecked_Access);

         elsif Name = "constants" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Constants'Unchecked_Access);

         elsif Name = "variables" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Variables'Unchecked_Access);

         elsif Name = "subprograms" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Subprograms'Unchecked_Access);

         elsif Name = "generic_instantiations" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities =>
                   Self.Entity.Generic_Instantiations'Unchecked_Access);

         elsif Name = "name" then
            return String_Proxy'(Content => Self.Entity.Name);

         elsif Name = "qualified_name" then
            return String_Proxy'(Content => Self.Entity.Qualified_Name);

         elsif Name = "code" then
            return
              String_Proxy'
                (Content =>
                   GNATdoc.Comments.Helpers.Get_Ada_Code_Snippet
                     (Self.Entity.Documentation).Join_Lines (VSS.Strings.LF));

         elsif Name = "description" then
            return
              String_Proxy'
                (Content =>
                   GNATdoc.Comments.Helpers.Get_Plain_Text_Description
                     (Self.Entity.Documentation).Join_Lines (VSS.Strings.LF));

         --  elsif Name = "all" then
         --     return
         --       Entity_Information_Set_Proxy'
         --         (Index_Entities =>
         --            Self.Entity.Generic_Instantiations'Unchecked_Access);

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
        (Self : in out TOC_Iterator)
         return VSS.XML.Templates.Proxies.Abstract_Proxy'Class is
      begin
         return
           Entity_Information_Proxy'
             (Entity => Entity_Information_Sets.Element (Self.Position),
              Nested => <>);
      end Element;

      -------------
      -- Content --
      -------------

      overriding function Content
        (Self : String_Proxy) return VSS.Strings.Virtual_String is
      begin
         return Self.Content;
      end Content;

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
         return Self.Index_Entities.Is_Empty;
      end Is_Empty;

      --------------
      -- Iterator --
      --------------

      overriding function Iterator
        (Self : in out Entity_Information_Set_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class is
      begin
         return TOC_Iterator'(Entities => Self.Index_Entities, Position => <>);
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

      -----------
      -- Value --
      -----------

      overriding function Value
        (Self : TOC_Iterator;
         Path : VSS.String_Vectors.Virtual_String_Vector)
         return VSS.XML.Templates.Values.Value
      is
         use type VSS.Strings.Virtual_String;

      begin
         if Path = ["id"] then
            return
              (Kind         => VSS.XML.Templates.Values.String,
               String_Value =>
                 Digest
                   (Entity_Information_Sets.Element
                        (Self.Position).Signature));

         elsif Path = ["full_href"] then
            return
              (Kind         => VSS.XML.Templates.Values.String,
               String_Value =>
                 Digest
                   (Entity_Information_Sets.Element (Self.Position).Signature)
               & ".html");

         elsif Path = ["local_href"] then
            return
              (Kind         => VSS.XML.Templates.Values.String,
               String_Value =>
                 "#"
                    & Digest
                        (Entity_Information_Sets.Element
                           (Self.Position).Signature));

         elsif Path = ["local_id"] then
            return
              (Kind         => VSS.XML.Templates.Values.String,
               String_Value =>
                 Digest
                   (Entity_Information_Sets.Element
                        (Self.Position).Signature));
         end if;

         return
           (Kind    => VSS.XML.Templates.Values.Error,
            Message => "unknown value '" & Path.Join ('/') & "'");
      end Value;

   end Proxies;

   --------------
   -- Generate --
   --------------

   procedure Generate is
      Index_Entities : aliased Entity_Information_Sets.Set;

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

      declare
         Input  : Input_Sources.File.File_Input;
         Reader : VSS.XML.XmlAda_Readers.XmlAda_Reader;
         Filter : aliased VSS.XML.Templates.Processors.XML_Template_Processor;
         Writer : aliased VSS.HTML.Writers.HTML5_Writer;
         Output : aliased Streams.Output_Text_Stream;

      begin
         --  Open input and output files.

         Input_Sources.File.Open
           ("../share/gnatdoc/html/template/index.xhtml", Input);
         Output.Open (GNATCOLL.VFS.Create ("index.html"));

         --  Connect components

         Writer.Set_Output_Stream (Output'Unchecked_Access);
         Filter.Set_Content_Handler (Writer'Unchecked_Access);
         Reader.Set_Content_Handler (Filter'Unchecked_Access);

         --  Bind information

         Filter.Bind
           (["gnatdoc", "toc"],
            new Proxies.Entity_Information_Set_Proxy'
              (Index_Entities => Index_Entities'Unchecked_Access));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;

      for Item of Index_Entities loop
         Generate_Entity_Documentation_Page (Item);
      end loop;
   end Generate;

   ----------------------------------------
   -- Generate_Entity_Documentation_Page --
   ----------------------------------------

   procedure Generate_Entity_Documentation_Page
     (Entity : not null Entity_Information_Access)
   is
      Name       : constant String :=
        Digest (To_UTF_8_String (Entity.Signature)) & ".html";
      File       : Writable_File :=
        Create (Filesystem_String (Name)).Write_File;
      All_Nested : Entity_Information_Sets.Set;

      procedure Generate_TOC
        (Title : String;
         Set   : Entity_Information_Sets.Set);

      ------------------
      -- Generate_TOC --
      ------------------

      procedure Generate_TOC
        (Title : String;
         Set   : Entity_Information_Sets.Set) is
      begin
         if not Set.Is_Empty then
            All_Nested.Union (Set);

            Write (File, "<h3>" & Title & "</h3>");
            Write (File, "<ul>");

            for Item of Set loop
               Write
                 (File,
                  "<li><a href='#"
                  & Digest (To_UTF_8_String (Item.Signature)) & "'>"
                  & To_UTF_8_String (Item.Name) & "</a></li>");
            end loop;

            Write (File, "</ul>");
         end if;
      end Generate_TOC;

   begin
      declare
         Input  : Input_Sources.File.File_Input;
         Reader : VSS.XML.XmlAda_Readers.XmlAda_Reader;
         Filter : aliased VSS.XML.Templates.Processors.XML_Template_Processor;
         Writer : aliased VSS.HTML.Writers.HTML5_Writer;
         Output : aliased Streams.Output_Text_Stream;
         Nested : Entity_Information_Sets.Set;

      begin
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
         Nested.Union (Entity.Generic_Instantiations);

         --  Open input and output files.

         Input_Sources.File.Open
           ("../share/gnatdoc/html/template/doc.xhtml", Input);
         Output.Open (GNATCOLL.VFS.Create (Filesystem_String (Name)));

         --  Connect components

         Writer.Set_Output_Stream (Output'Unchecked_Access);
         Filter.Set_Content_Handler (Writer'Unchecked_Access);
         Reader.Set_Content_Handler (Filter'Unchecked_Access);

         --  Bind information

         Filter.Bind
           (["gnatdoc", "entity"],
            new Proxies.Entity_Information_Proxy'
              (Entity => Entity, Nested => Nested));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;
   end Generate_Entity_Documentation_Page;

   -----------------------
   -- Is_Private_Entity --
   -----------------------

   function Is_Private_Entity
     (Entity : not null Entity_Information_Access) return Boolean is
   begin
      return
        (Entity.Is_Private and not Options.Options.Generate_Private)
        or Entity.Documentation.Is_Private
        or (not Entity.Enclosing.Is_Empty
              and then Is_Private_Entity (To_Entity (Entity.Enclosing)));
   end Is_Private_Entity;

end GNATdoc.Backend;
