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

with Ada.Wide_Wide_Text_IO;
with Ada.Strings.Wide_Wide_Fixed;

with GNAT.SHA256;
with GNATCOLL.VFS;

with GNATdoc.Comments.Helpers;
with GNATdoc.Entities;

with VSS.Strings.Conversions;

package body GNATdoc.Backend is

   use Ada.Strings.Wide_Wide_Fixed;
   use Ada.Wide_Wide_Text_IO;
   use GNAT.SHA256;
   use GNATCOLL.VFS;
   use GNATdoc.Comments;
   use GNATdoc.Comments.Helpers;
   use GNATdoc.Entities;
   use VSS.Strings.Conversions;

   procedure Dump
     (Entity : not null Entity_Information_Access;
      Indent : Natural);

   procedure Dump
     (File   : in out Writable_File;
      Entity : not null Entity_Information_Access;
      Indent : Natural);

   procedure Generate_Entity_Documentation_Page
     (Entity : not null Entity_Information_Access);

   ----------
   -- Dump --
   ----------

   procedure Dump
     (Entity : not null Entity_Information_Access;
      Indent : Natural) is
   begin
      --  Put_Line ((Indent * "  ") & To_Wide_Wide_String (Entity.Signature));

      for Child of All_Entities (Entity.all) loop
         Dump (Child, Indent + 1);
      end loop;
   end Dump;

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

   ----------
   -- Dump --
   ----------

   procedure Dump
     (File   : in out Writable_File;
      Entity : not null Entity_Information_Access;
      Indent : Natural) is
   begin
      if not Entity.Signature.Is_Empty then
         Write
           (File,
            "<li><a href='"
            & Digest (To_UTF_8_String (Entity.Signature))
            & ".html' target='document-content'>"
            & To_UTF_8_String (Entity.Qualified_Name) & "</a></li>");
      end if;

      Write (File, "<ul>");
      for Child of Entity.Packages loop
      --  for Child of All_Entities (Entity.all) loop
         Dump (File, Child, Indent + 1);
      end loop;
      Write (File, "</ul>");

      Generate_Entity_Documentation_Page (Entity);
   end Dump;

   --------------
   -- Generate --
   --------------

   procedure Generate is
      File : Virtual_File := Create ("index.html");

   begin
      Dump (Global_Entities'Access, 0);

      declare
         W : Writable_File := File.Write_File;

      begin
         Write (W, "<!DOCTYPE html>");

         Write (W, "<html class='main'>");
         Write (W, "<head>");
         Write (W, "<link rel='stylesheet' href='gnatdoc.css'>");
         Write (W, "</head>");
         Write (W, "<body class='main'>");
         Write (W, "<div class='side-navigation'>");
         --  Write (W, "<ul>");
         Dump (W, Global_Entities'Access, 0);
         --  Write (W, "</ul>");
         Write (W, "</div>");
         Write (W, "<div class='document-content'>");
         Write (W, "<iframe name='document-content'/>");
         Write (W, "</div>");
         Write (W, "</body>");
         Write (W, "</html>");

         Close (W);
      end;
   end Generate;

end GNATdoc.Backend;
