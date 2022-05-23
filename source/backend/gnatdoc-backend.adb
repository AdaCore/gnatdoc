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

with GNAT.SHA256;
with GNATCOLL.VFS;

with GNATdoc.Comments.Helpers;
with GNATdoc.Entities;

with VSS.Strings.Conversions;

package body GNATdoc.Backend is

   use GNAT.SHA256;
   use GNATCOLL.VFS;
   use GNATdoc.Comments.Helpers;
   use GNATdoc.Entities;
   use VSS.Strings.Conversions;

   procedure Generate_Entity_Documentation_Page
     (Entity : not null Entity_Information_Access);

   --------------
   -- Generate --
   --------------

   procedure Generate is
      Index_File     : constant Virtual_File := Create ("index.html");
      Index_Entities : Entity_Information_Sets.Set;

   begin
      Index_Entities.Union (TOC_Entities.Packages);
      Index_Entities.Union (TOC_Entities.Subprograms);

      declare
         File : Writable_File := Index_File.Write_File;

      begin
         Write (File, "<!DOCTYPE html>");

         Write (File, "<html class='main'>");
         Write (File, "<head>");
         Write (File, "<link rel='stylesheet' href='gnatdoc.css'>");
         Write (File, "</head>");
         Write (File, "<body class='main'>");
         Write (File, "<div class='side-navigation'>");
         Write (File, "<ul>");

         for Item of Index_Entities loop
            Write
              (File,
               "<li><a href='"
               & Digest (To_UTF_8_String (Item.Signature))
               & ".html' target='document-content'>"
               & To_UTF_8_String (Item.Qualified_Name) & "</a></li>");

            Generate_Entity_Documentation_Page (Item);
         end loop;

         Write (File, "</ul>");
         Write (File, "</div>");
         Write (File, "<div class='document-content'>");
         Write (File, "<iframe name='document-content'/>");
         Write (File, "</div>");
         Write (File, "</body>");
         Write (File, "</html>");

         Close (File);
      end;
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
      Generate_TOC ("Record Types", Entity.Record_Types);
      Generate_TOC ("Tagged Types", Entity.Tagged_Types);
      Generate_TOC ("Access Types", Entity.Access_Types);
      Generate_TOC ("Subtypes", Entity.Subtypes);
      Generate_TOC ("Constants", Entity.Constants);
      Generate_TOC ("Variables", Entity.Variables);
      Generate_TOC ("Subprograms", Entity.Subprograms);

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

end GNATdoc.Backend;
