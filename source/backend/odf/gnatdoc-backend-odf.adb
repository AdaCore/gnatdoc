------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
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

with Input_Sources.File;
with VSS.XML.XmlAda_Readers;
with VSS.XML.Templates.Processors;
with VSS.XML.Writers.Simple;

with GNATdoc.Backend.ODF_Markup.Image_Utilities;
with GNATdoc.Entities.Proxies;
with GNATdoc.Projects;
with Streams;

package body GNATdoc.Backend.ODF is

   ------------------------------
   -- Add_Command_Line_Options --
   ------------------------------

   overriding procedure Add_Command_Line_Options
     (Self   : ODF_Backend;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      null;
   end Add_Command_Line_Options;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out ODF_Backend) is
      Index_Entities : aliased GNATdoc.Entities.Entity_Information_Sets.Set;

      Input     : Input_Sources.File.File_Input;
      Reader    : VSS.XML.XmlAda_Readers.XmlAda_Reader;
      Processor : aliased VSS.XML.Templates.Processors.XML_Template_Processor;
      Writer    : aliased VSS.XML.Writers.Simple.Simple_XML_Writer;
      Output    : aliased Streams.Output_Text_Stream;
      Path      : VSS.String_Vectors.Virtual_String_Vector;

   begin
      for Item of GNATdoc.Entities.Globals.Packages loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of GNATdoc.Entities.Globals.Contain_Subprograms loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of GNATdoc.Entities.Globals.Package_Renamings loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      for Item of GNATdoc.Entities.Globals.Generic_Instantiations loop
         if not Is_Private_Entity (Item) then
            Index_Entities.Insert (Item);
         end if;
      end loop;

      --  Open input and output files.

      Path.Clear;
      Path.Append ("template");
      Path.Append ("documentation.fodt");
      Input_Sources.File.Open
        (String (Self.Lookup_Resource_File (Path).Full_Name.all),
         Input);
      Output.Open
        (GNATCOLL.VFS.Create_From_Dir
           (Self.Output_Root, "documentation.fodt"));

      --  Connect components

      Writer.Set_Output_Stream (Output'Unchecked_Access);
      Writer.Set_Attribute_Syntax (VSS.XML.Writers.Simple.Double_Quoted);
      Processor.Set_Content_Handler (Writer'Unchecked_Access);
      --  Processor.Set_Lexical_Handler (Writer'Unchecked_Access);
      Reader.Set_Content_Handler (Processor'Unchecked_Access);
      Reader.Enable_Namespace_Feature;
      Reader.Enable_Namespace_Prefixes_Feature;

      --  Bind information

      Path.Clear;
      Path.Append ("gnatdoc");
      Path.Append ("toc");
      Processor.Bind
        (Path,
         new GNATdoc.Entities.Proxies.Entity_Information_Set_Proxy'
           (Entities => Index_Entities'Unchecked_Access,
            OOP_Mode => False));  --  XXX Self.OOP_Mode));

      --  Process template

      Reader.Parse (Input);

      --  Close input and output files.

      Input.Close;
      Output.Close;
   end Generate;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out ODF_Backend) is
   begin
      Abstract_Backend (Self).Initialize;

      if Self.Image_Directories.Is_Empty then
         GNATdoc.Backend.ODF_Markup.Image_Utilities.Set_Image_Directories
           ([GNATdoc.Projects.Project_File_Directory]);

      else
         GNATdoc.Backend.ODF_Markup.Image_Utilities.Set_Image_Directories
           (Self.Image_Directories);
      end if;
   end Initialize;

   ----------------------------------
   -- Process_Command_Line_Options --
   ----------------------------------

   overriding procedure Process_Command_Line_Options
     (Self   : in out ODF_Backend;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      null;
   end Process_Command_Line_Options;

end GNATdoc.Backend.ODF;
