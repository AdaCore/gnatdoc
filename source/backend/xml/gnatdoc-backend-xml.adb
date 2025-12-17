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

with VSS.IRIs;
with VSS.Strings.Formatters.Generic_Integers;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.XML.Attributes.Containers;
with VSS.XML.Writers.Pretty;

with GNATdoc.Backend.XML_Namespaces;
with GNATdoc.Comments.XML_Helpers;
with Streams;

package body GNATdoc.Backend.XML is

   use GNATdoc.Backend.XML_Namespaces;

   package Character_Count_Formatters is
     new VSS.Strings.Formatters.Generic_Integers (VSS.Strings.Character_Count);
   use Character_Count_Formatters;
   --  XXX VSS 20251204+ provides it as
   --  `VSS.Strings.Formatters.Character_Offsets`.

   package Line_Count_Formatters is
     new VSS.Strings.Formatters.Generic_Integers (VSS.Strings.Line_Count);
   use Line_Count_Formatters;
   --  XXX VSS 20251204+ provides it as `VSS.Strings.Formatters.Line_Offsets`.

   Formal_Tag         : constant VSS.Strings.Virtual_String := "formal";
   Function_Tag       : constant VSS.Strings.Virtual_String := "function";
   Exception_Tag      : constant VSS.Strings.Virtual_String := "exception";
   Generic_Package_Declaration_Tag : constant VSS.Strings.Virtual_String :=
     "generic-package-declaration";
   Generic_Package_Instantiation_Tag : constant VSS.Strings.Virtual_String :=
     "generic-package-instantiation";
   Generic_Subprogram_Instantiation_Tag : constant
     VSS.Strings.Virtual_String := "generic-subprogram-instantiation";
   GNATdoc_Tag        : constant VSS.Strings.Virtual_String := "gnatdoc";
   Interface_Type_Tag : constant VSS.Strings.Virtual_String :=
     "interface-type";
   Named_Number_Tag   : constant VSS.Strings.Virtual_String :=
     "named-number";
   Object_Tag         : constant VSS.Strings.Virtual_String := "object";
   Package_Body_Tag   : constant VSS.Strings.Virtual_String := "package-body";
   Package_Declaration_Tag : constant VSS.Strings.Virtual_String :=
     "package-declaration";
   Procedure_Tag      : constant VSS.Strings.Virtual_String := "procedure";
   Tagged_Type_Tag    : constant VSS.Strings.Virtual_String := "tagged-type";
   Type_Tag           : constant VSS.Strings.Virtual_String := "type";

   function Entity_Tag
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return VSS.Strings.Virtual_String;

   ----------------
   -- Entity_Tag --
   ----------------

   function Entity_Tag
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return VSS.Strings.Virtual_String is
   begin
      case Entity.Kind is
         when GNATdoc.Entities.Undefined =>
            raise Program_Error with "not classified entity";

         when GNATdoc.Entities.Ada_Tagged_Type =>
            return Tagged_Type_Tag;

         when GNATdoc.Entities.Ada_Interface_Type =>
            return Interface_Type_Tag;

         when GNATdoc.Entities.Ada_Other_Type =>
            return Type_Tag;

         when GNATdoc.Entities.Ada_Named_Number =>
            return Named_Number_Tag;

         when GNATdoc.Entities.Ada_Object =>
            return Object_Tag;

         when GNATdoc.Entities.Ada_Exception =>
            return Exception_Tag;

         when GNATdoc.Entities.Ada_Function =>
            return Function_Tag;

         when GNATdoc.Entities.Ada_Procedure =>
            return Procedure_Tag;

         when GNATdoc.Entities.Ada_Package_Declaration =>
            return Package_Declaration_Tag;

         when GNATdoc.Entities.Ada_Package_Body =>
            return Package_Body_Tag;

         when GNATdoc.Entities.Ada_Formal =>
            return Formal_Tag;

         when GNATdoc.Entities.Ada_Generic_Package_Declaration =>
            return Generic_Package_Declaration_Tag;

         when GNATdoc.Entities.Ada_Generic_Package_Instantiation =>
            return Generic_Package_Instantiation_Tag;

         when GNATdoc.Entities.Ada_Generic_Subprogram_Instantiation =>
            return Generic_Subprogram_Instantiation_Tag;
      end case;
   end Entity_Tag;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out XML_Backend) is

      procedure Generate
        (Writer  : in out VSS.XML.Writers.XML_Writer'Class;
         Entity  : not null GNATdoc.Entities.Entity_Information_Access;
         Success : in out Boolean);

      --------------
      -- Generate --
      --------------

      procedure Generate
        (Writer  : in out VSS.XML.Writers.XML_Writer'Class;
         Entity  : not null GNATdoc.Entities.Entity_Information_Access;
         Success : in out Boolean)
      is
         Attributes        : VSS.XML.Attributes.Containers.Attributes;
         Signatures        : VSS.String_Vectors.Virtual_String_Vector;
         Location_Template : VSS.Strings.Templates.Virtual_String_Template :=
           "{}:{}:{}";

      begin
         Attributes.Clear;
         Attributes.Insert
           (VSS.IRIs.Empty_IRI,
            "location",
            Location_Template.Format
              (VSS.Strings.Formatters.Strings.Image (Entity.Location.File),
               Image (Entity.Location.Line),
               Image (Entity.Location.Column)));
         Attributes.Insert
           (VSS.IRIs.Empty_IRI, "signature", Entity.Signature.Image);
         Attributes.Insert (VSS.IRIs.Empty_IRI, "name", Entity.Name);
         Attributes.Insert
           (VSS.IRIs.Empty_IRI, "qualified_name", Entity.Qualified_Name);

         if not GNATdoc.Entities.Is_Undefined (Entity.Parent_Type) then
            Attributes.Insert
              (VSS.IRIs.Empty_IRI,
               "parent_type",
               Entity.Parent_Type.Signature.Image);
         end if;

         for Progenitor of Entity.Progenitor_Types loop
            Signatures.Append (Progenitor.Signature.Image);
         end loop;

         if not Signatures.Is_Empty then
            Attributes.Insert
              (VSS.IRIs.Empty_IRI, "progenitor_types", Signatures.Join (' '));
         end if;

         if not Entity.Type_Signature.Image.Is_Empty then
            Attributes.Insert
              (VSS.IRIs.Empty_IRI, "type", Entity.Type_Signature.Image);
         end if;

         Writer.Start_Element
           (GNATdoc_Namespace, Entity_Tag (Entity), Attributes, Success);

         GNATdoc.Comments.XML_Helpers.Generate
           (Entity.Documentation, Writer, Success);

         for E of Entity.Contain_Entities loop
            Generate (Writer, E, Success);
         end loop;

         Writer.End_Element (GNATdoc_Namespace, Entity_Tag (Entity), Success);
      end Generate;

      Writer     : aliased VSS.XML.Writers.Pretty.Pretty_XML_Writer;
      Output     : aliased Streams.Output_Text_Stream;
      Success    : Boolean := True;
      Attributes : VSS.XML.Attributes.Containers.Attributes;

   begin
      --  Open output file.

      Output.Open
        (GNATCOLL.VFS.Create_From_Dir
           (Self.Output_Root, "documentation.xml"));

      --  Connect components

      Writer.Set_Output_Stream (Output'Unchecked_Access);
      Writer.Set_Indent (2);

      --  Generate XML document

      Writer.Start_Document (Success);
      Writer.Start_Prefix_Mapping ("", GNATdoc_Namespace, Success);

      Attributes.Clear;
      Writer.Start_Element
        (GNATdoc_Namespace, GNATdoc_Tag, Attributes, Success);

      for E of GNATdoc.Entities.Globals.Contain_Entities loop
         Generate (Writer, E, Success);
      end loop;

      Writer.End_Element (GNATdoc_Namespace, GNATdoc_Tag, Success);

      --  Close output file.

      Output.Close;
   end Generate;

end GNATdoc.Backend.XML;
