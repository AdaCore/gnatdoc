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

with GNATCOLL.VFS;

with VSS.Strings.Conversions;
with VSS.Strings;
with VSS.Characters;
with VSS.Characters.Latin;
with VSS.Strings.Character_Iterators;

with GNATdoc.Entities;
with GNATdoc.Options;
with Streams;

with GNATdoc.Entities.YAML;

package body GNATdoc.Backend.Jekyll is

   use GNATCOLL.VFS;
   use GNATdoc.Entities;
   use VSS.Strings.Conversions;

   function Filename (Entity : Entity_Information)
                      return VSS.Strings.Virtual_String;

   procedure Generate_Entity_Documentation_Page
     (Self   : in out Jekyll_Backend'Class;
      Entity : not null Entity_Information_Access);

   function Is_Private_Entity
     (Entity : not null Entity_Information_Access) return Boolean;
   --  Return True when given entity is private package, or explicitly marked
   --  as private entity, or enclosed by the private package, or enclosed by
   --  the entity marked as private entity.

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out Jekyll_Backend) is
      use VSS.Strings;

      Index_Entities : aliased Entity_Information_Sets.Set;

      Name : constant String := "index.md";

      Output : aliased Streams.Output_Text_Stream;

      Content : VSS.Strings.Virtual_String;

      Global_Packages : Entity_Information_Sets.Set;
      Global_Subprograms : Entity_Information_Sets.Set;
      Global_Renamings : Entity_Information_Sets.Set;
   begin
      --  Open output file

      Output.Open
        (GNATCOLL.VFS.Create_From_Dir
           (Self.Output_Root, Filesystem_String (Name)));

      for Item of Globals.Packages loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
            Global_Packages.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Subprograms loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
            Global_Subprograms.Insert (Item);
         end if;
      end loop;

      for Item of Globals.Package_Renamings loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
            Global_Renamings.Insert (Item);
         end if;
      end loop;

      Append (Content, "---");
      Append (Content, VSS.Characters.Latin.Line_Feed);

      --  Custom Front Matter
      for Line of Options.Backend_Options.Jekyll_Front_Matter loop
         Append (Content, Line);
         Append (Content, VSS.Characters.Latin.Line_Feed);
      end loop;

      Append (Content, "layout: gnatdoc_index");
      Append (Content, VSS.Characters.Latin.Line_Feed);
      Append (Content, "gnatdoc: {");
      if not Global_Packages.Is_Empty then
         Append (Content, "packages: ");
         Append (Content, GNATdoc.Entities.YAML.To_YAML (Global_Packages,
                 Recursive => False));
         Append (Content, ", ");
      end if;

      if not Global_Renamings.Is_Empty then
         Append (Content, " renamings: ");
         Append (Content, GNATdoc.Entities.YAML.To_YAML (Global_Renamings,
                 Recursive => False));
         Append (Content, ", ");
      end if;

      if not Global_Subprograms.Is_Empty then
         Append (Content, ", subprograms: ");
         Append (Content, GNATdoc.Entities.YAML.To_YAML (Global_Subprograms,
                 Recursive => False));
         Append (Content, ", ");
      end if;
      Append (Content, "}");
      Append (Content, VSS.Characters.Latin.Line_Feed);

      for Item of Index_Entities loop
         Self.Generate_Entity_Documentation_Page (Item);
      end loop;

      Append (Content, "---");
      Append (Content, VSS.Characters.Latin.Line_Feed);

      declare
         Iterator : VSS.Strings.Character_Iterators.Character_Iterator :=
           Content.Before_First_Character;

         Unused : Boolean;
      begin
         while Iterator.Forward loop
            Output.Put (Iterator.Element, Unused);
         end loop;
      end;

      --  Close output file
      Output.Close;

   end Generate;

   --------------
   -- Filename --
   --------------

   function Filename (Entity : Entity_Information)
                      return VSS.Strings.Virtual_String
   is
      use VSS.Strings;
      use VSS.Characters;
      use VSS.Strings.Character_Iterators;

      Result : VSS.Strings.Virtual_String;
      J : Character_Iterator := Entity.Signature.Before_First_Character;
      C : Virtual_Character;
   begin

      while J.Forward loop
         C := J.Element;
         if C = '.' then
            Append (Result, '-');
         else
            Append (Result, C);
         end if;
      end loop;

      return Result;
   end Filename;

   ----------------------------------------
   -- Generate_Entity_Documentation_Page --
   ----------------------------------------

   procedure Generate_Entity_Documentation_Page
     (Self   : in out Jekyll_Backend'Class;
      Entity : not null Entity_Information_Access)
   is

      Name       : constant String :=
        To_UTF_8_String (Filename (Entity.all)) & ".md";

      Output : aliased Streams.Output_Text_Stream;

      procedure Put (Str : VSS.Strings.Virtual_String);
      procedure Put_Line (Str : VSS.Strings.Virtual_String);

      ---------
      -- Put --
      ---------

      procedure Put (Str : VSS.Strings.Virtual_String) is
         Iterator : VSS.Strings.Character_Iterators.Character_Iterator :=
           Str.Before_First_Character;

         Unused : Boolean;
      begin
         while Iterator.Forward loop
            Output.Put (Iterator.Element, Unused);
         end loop;
      end Put;

      --------------
      -- Put_Line --
      --------------

      procedure Put_Line (Str : VSS.Strings.Virtual_String) is
         Unused : Boolean;
      begin
         Put (Str);
         Output.Put (VSS.Characters.Latin.Line_Feed, Unused);
      end Put_Line;

   begin
      --  Open output file

      Output.Open
        (GNATCOLL.VFS.Create_From_Dir
           (Self.Output_Root, Filesystem_String (Name)));

      --  Front Matter start
      Put_Line ("---");

      for Line of Options.Backend_Options.Jekyll_Front_Matter loop
         Put_Line (Line);
      end loop;

      Put_Line ("layout: gnatdoc");
      Put ("gnatdoc: ");
      Put_Line (GNATdoc.Entities.YAML.To_YAML (Entity.all));

      --  Front Matter end
      Put_Line ("---");

      --  Close output file

      Output.Close;
   end Generate_Entity_Documentation_Page;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out Jekyll_Backend) is

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
     (Self : in out Jekyll_Backend) return VSS.Strings.Virtual_String is
   begin
      return "jekyll";
   end Name;

end GNATdoc.Backend.Jekyll;
