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

with VSS.HTML.Writers;
with VSS.Strings.Conversions;
with VSS.String_Vectors;
with VSS.XML.Templates.Processors;
with VSS.XML.Templates.Proxies.Strings;
with VSS.XML.Templates.Values;
with VSS.XML.XmlAda_Readers;

with GNATdoc.Comments.Helpers;
with GNATdoc.Comments.Proxies;
with GNATdoc.Entities;
with GNATdoc.Options;
with Streams;

package body GNATdoc.Backend.HTML is

   use GNAT.SHA256;
   use GNATCOLL.VFS;
   use GNATdoc.Comments.Helpers;
   use GNATdoc.Entities;
   use VSS.Strings.Conversions;

   procedure Generate_Entity_Documentation_Page
     (Self   : in out HTML_Backend'Class;
      Entity : not null Entity_Information_Access);

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
      with record
         Entities : not null access Entity_Information_Sets.Set;
         Position : Entity_Information_Sets.Cursor;
      end record;

      overriding function Next (Self : in out TOC_Iterator) return Boolean;

      overriding function Element
        (Self : in out TOC_Iterator)
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

         elsif Name = "exceptions" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities => Self.Entity.Exceptions'Unchecked_Access);

         elsif Name = "generic_instantiations" then
            return
              Entity_Information_Set_Proxy'
                (Index_Entities =>
                   Self.Entity.Generic_Instantiations'Unchecked_Access);

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
              GNATdoc.Comments.Proxies.Structured_Comment_Proxy'
                (Documentation => Self.Entity.Documentation'Unchecked_Access);

         elsif Name = "id" then
            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Text => Digest (Self.Entity.Signature));

         elsif Name = "full_href" then
            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Text => Digest (Self.Entity.Signature) & ".html");

         elsif Name = "local_href" then
            return
              VSS.XML.Templates.Proxies.Strings.Virtual_String_Proxy'
                (Text => "#" & Digest (Self.Entity.Signature));

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

   end Proxies;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out HTML_Backend) is
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
              (Index_Entities => Index_Entities'Unchecked_Access));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;

      for Item of Index_Entities loop
         Self.Generate_Entity_Documentation_Page (Item);
      end loop;
   end Generate;

   ----------------------------------------
   -- Generate_Entity_Documentation_Page --
   ----------------------------------------

   procedure Generate_Entity_Documentation_Page
     (Self   : in out HTML_Backend'Class;
      Entity : not null Entity_Information_Access)
   is
      Name       : constant String :=
        Digest (To_UTF_8_String (Entity.Signature)) & ".html";
      File       : Writable_File :=
        Create (Filesystem_String (Name)).Write_File;
      All_Nested : Entity_Information_Sets.Set;

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
         Nested.Union (Entity.Generic_Instantiations);

         --  Open input and output files.

         Path.Clear;
         Path.Append ("template");
         Path.Append ("doc.xhtml");
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
              (Entity => Entity, Nested => Nested));

         --  Process template

         Reader.Parse (Input);

         --  Close input and output files.

         Input.Close;
         Output.Close;
      end;
   end Generate_Entity_Documentation_Page;

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

      Copy_Static (Self.System_Resources_Root);
      Copy_Static (Self.Project_Resources_Root);
   end Initialize;

   -----------------------
   -- Is_Private_Entity --
   -----------------------

   function Is_Private_Entity
     (Entity : not null Entity_Information_Access) return Boolean is
   begin
      return
        (Entity.Is_Private
           and not GNATdoc.Options.Frontend_Options.Generate_Private)
        or Entity.Documentation.Is_Private
        or (not Entity.Enclosing.Is_Empty
              and then Is_Private_Entity (To_Entity (Entity.Enclosing)));
   end Is_Private_Entity;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out HTML_Backend) return VSS.Strings.Virtual_String is
   begin
      return "html";
   end Name;

end GNATdoc.Backend.HTML;
