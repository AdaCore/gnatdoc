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

pragma Ada_2022;

with GNAT.SHA256;
with GNATCOLL.VFS;

with Input_Sources.File;

with VSS.HTML.Writers;
with VSS.Strings.Formatters.Virtual_Files;
with VSS.Strings.Conversions;
with VSS.Strings.Templates;
with VSS.String_Vectors;
with VSS.XML.Templates.Processors;
with VSS.XML.Templates.Proxies.Booleans;
with VSS.XML.XmlAda_Readers;

with GNATdoc.Entities.Proxies;
with GNATdoc.Messages;
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

   procedure Union
     (Container : in out Entity_Information_Sets.Set;
      Items     : Entity_Reference_Sets.Set);

   OOP_Style_Option : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "html-oop-style",
      Description =>
        VSS.Strings.To_Virtual_String
          ("Group subprograms by tagged types, generating a page for each"
           & " tagged type"));

   ------------------------------
   -- Add_Command_Line_Options --
   ------------------------------

   overriding procedure Add_Command_Line_Options
     (Self   : HTML_Backend;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      Parser.Add_Option (OOP_Style_Option);
   end Add_Command_Line_Options;

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

      for Item of Globals.Contain_Subprograms loop
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
              (Entities => Index_Entities'Unchecked_Access,
               OOP_Mode => Self.OOP_Mode));

         Path.Clear;
         Path.Append ("gnatdoc");
         Path.Append ("classes_toc");
         Filter.Bind
           (Path,
            new Proxies.Entity_Information_Set_Proxy'
              (Entities => Class_Index_Entities'Unchecked_Access,
               OOP_Mode => Self.OOP_Mode));

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
        Digest (To_UTF_8_String (Entity.Signature.Image)) & ".html";

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
         Union (Nested, Entity.Belong_Subprograms);
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
        Digest (To_UTF_8_String (Entity.Signature.Image)) & ".html";

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

         if Self.OOP_Mode then
            Union (Nested, Entity.Belong_Subprograms);

         else
            Nested.Union (Entity.Contain_Subprograms);
         end if;

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

      Copy_Static (Self.System_Resources_Root);
      Copy_Static (Self.Project_Resources_Root);

      if not Self.Image_Directories.Is_Empty then
         declare
            Images_Dir : constant GNATCOLL.VFS.Virtual_File :=
              Self.Output_Root / "images";
            Success    : Boolean;

         begin
            Images_Dir.Make_Dir;

            for Directory of reverse Self.Image_Directories loop
               if GNATCOLL.VFS.Greatest_Common_Path
                 ([Self.Output_Root, Directory]) = Directory
               then
                  GNATdoc.Messages.Report_Warning
                    (VSS.Strings.Templates.To_Virtual_String_Template
                     ("image directory `{:fullname}` can't be parent of"
                        & " output directory").Format
                       (VSS.Strings.Formatters.Virtual_Files.Image
                            (Directory)));

               else
                  Directory.Copy (Images_Dir.Full_Name.all, Success);
               end if;
            end loop;
         end;
      end if;
   end Initialize;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out HTML_Backend) return VSS.Strings.Virtual_String is
   begin
      return "html";
   end Name;

   ----------------------------------
   -- Process_Command_Line_Options --
   ----------------------------------

   overriding procedure Process_Command_Line_Options
     (Self   : in out HTML_Backend;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      if Parser.Is_Specified (OOP_Style_Option) then
         Self.OOP_Mode := True;
      end if;
   end Process_Command_Line_Options;

   -----------
   -- Union --
   -----------

   procedure Union
     (Container : in out Entity_Information_Sets.Set;
      Items     : Entity_Reference_Sets.Set) is
   begin
      for Item of Items loop
         Container.Insert (To_Entity (Item.Signature));
      end loop;
   end Union;

end GNATdoc.Backend.HTML;
