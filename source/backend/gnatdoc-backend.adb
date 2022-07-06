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

      type TOC_Proxy is limited
        new VSS.XML.Templates.Proxies.Abstract_Iterable_Proxy with record
         Index_Entities : Entity_Information_Sets.Set;
      end record;

      overriding function Iterator
        (Self : in out TOC_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class;

   end Proxies;

   -------------
   -- Proxies --
   -------------

   package body Proxies is

      use type VSS.String_Vectors.Virtual_String_Vector;

      type TOC_Proxy_Access is access all TOC_Proxy;

      type TOC_Iterator is
      limited new VSS.XML.Templates.Proxies.Abstract_Proxy
        and VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator
        and VSS.XML.Templates.Proxies.Abstract_Content_Proxy
        and VSS.XML.Templates.Proxies.Abstract_Value_Proxy
      with record
         TOC      : TOC_Proxy_Access;
         Position : Entity_Information_Sets.Cursor;
      end record;

      overriding function Next (Self : in out TOC_Iterator) return Boolean;

      overriding function Content
        (Self : TOC_Iterator;
         Path : VSS.String_Vectors.Virtual_String_Vector)
         return VSS.Strings.Virtual_String;

      overriding function Value
        (Self : TOC_Iterator;
         Path : VSS.String_Vectors.Virtual_String_Vector)
         return VSS.XML.Templates.Values.Value;

      -------------
      -- Content --
      -------------

      overriding function Content
        (Self : TOC_Iterator;
         Path : VSS.String_Vectors.Virtual_String_Vector)
         return VSS.Strings.Virtual_String is
      begin
         if Path = ["title"] then
            return Entity_Information_Sets.Element (Self.Position).Name;

         else
            return "Hello!";
         end if;
      end Content;

      --------------
      -- Iterator --
      --------------

      overriding function Iterator
        (Self : in out TOC_Proxy)
         return VSS.XML.Templates.Proxies.Abstract_Iterable_Iterator'Class is
      begin
         return TOC_Iterator'(TOC => Self'Unchecked_Access, Position => <>);
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
              Entity_Information_Sets.First (Self.TOC.Index_Entities);
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
         if Path = ["href"] then
            return
              (Kind         => VSS.XML.Templates.Values.String,
               String_Value =>
                 To_Virtual_String
                   (Digest
                        (To_UTF_8_String
                           (Entity_Information_Sets.Element
                              (Self.Position).Signature)))
               & ".html");
         end if;

         return (Kind => VSS.XML.Templates.Values.Error);
      end Value;

   end Proxies;

   --------------
   -- Generate --
   --------------

   procedure Generate is
      Index_Entities : Entity_Information_Sets.Set;

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
         Filter : aliased VSS.XML.Templates.XML_Template_Processor;
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
            new Proxies.TOC_Proxy'(Index_Entities => Index_Entities));

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
      Write (File, "<!DOCTYPE html>");

      Write (File, "<html>");
      Write (File, "<head>");
      Write (File, "<link rel='stylesheet' href='gnatdoc.css'>");
      Write (File, "</head>");
      Write (File, "<body class='content'>");

      Write (File, "<h1>" & To_UTF_8_String (Entity.Qualified_Name) & "</h1>");
      Write (File, "<h2>Entities</h2>");

      Generate_TOC ("Simple Types", Entity.Simple_Types);
      Generate_TOC ("Array Types", Entity.Array_Types);
      Generate_TOC ("Record Types", Entity.Record_Types);
      Generate_TOC ("Interface Types", Entity.Interface_Types);
      Generate_TOC ("Tagged Types", Entity.Tagged_Types);
      Generate_TOC ("Access Types", Entity.Access_Types);
      Generate_TOC ("Subtypes", Entity.Subtypes);
      Generate_TOC ("Constants", Entity.Constants);
      Generate_TOC ("Variables", Entity.Variables);
      Generate_TOC ("Subprograms", Entity.Subprograms);
      Generate_TOC ("Generic Instantiations", Entity.Generic_Instantiations);

      Write (File, "<h2>Description</h2>");

      Write (File, "<pre>");
      Write
        (File,
         To_UTF_8_String
           (Get_Plain_Text_Description
                (Entity.Documentation).Join_Lines (VSS.Strings.LF)));
      Write (File, "</pre>");

      for Item of All_Nested loop
         Write
           (File,
               "<h4 id='"
               & Digest (To_UTF_8_String (Item.Signature)) & "'>"
               & To_UTF_8_String (Item.Name) & "</h4>");

         Write (File, "<pre class='ada-code-snippet'>");

         for Line of Get_Ada_Code_Snippet (Item.Documentation) loop
            Write (File, To_UTF_8_String (Line) & ASCII.LF);
         end loop;

         Write (File, "</pre>");

         if Item.Documentation.Has_Documentation then
            Write (File, "<pre>");

            Write
              (File,
               To_UTF_8_String
                 (Get_Plain_Text_Description
                      (Item.Documentation).Join_Lines (VSS.Strings.LF)));

            Write (File, "</pre>");
         end if;
      end loop;

      Write (File, "</body>");
      Write (File, "</html>");

      Close (File);
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
