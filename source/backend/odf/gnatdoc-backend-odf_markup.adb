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
with VSS.XML.Events;
with VSS.XML.Namespaces;

with Markdown.Annotations.Visitors;
with Markdown.Block_Containers;
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Documents;
with Markdown.Parsers.GNATdoc_Enable;

package body GNATdoc.Backend.ODF_Markup is

   Draw_Namespace : constant VSS.IRIs.IRI :=
     VSS.IRIs.To_IRI ("urn:oasis:names:tc:opendocument:xmlns:drawing:1.0");
   Text_Namespace : constant VSS.IRIs.IRI :=
     VSS.IRIs.To_IRI ("urn:oasis:names:tc:opendocument:xmlns:text:1.0");

   Line_Break_Element : constant VSS.Strings.Virtual_String := "line-break";
   List_Element       : constant VSS.Strings.Virtual_String := "list";
   List_Item_Element  : constant VSS.Strings.Virtual_String := "list-item";
   P_Element          : constant VSS.Strings.Virtual_String := "p";

   Style_Name_Attribute : constant VSS.Strings.Virtual_String :=
     "style-name";

   GNATdoc_Paragraph_Style  : constant VSS.Strings.Virtual_String :=
     "GNATdoc_20_paragraph";
   GNATdoc_Code_Block_Style : constant VSS.Strings.Virtual_String :=
     "GNATdoc_20_code_20_block";
   GNATdoc_Code_Span_Style  : constant VSS.Strings.Virtual_String :=
     "GNATdoc_20_code_20_span";
   --  Names of styles predefined by GNATdoc

   type Annotated_Text_Builder is
     limited new Markdown.Annotations.Visitors.Annotated_Text_Visitor with
   record
      Image  : Boolean := False;
      Text   : VSS.Strings.Virtual_String;
      Stream : VSS.XML.Event_Vectors.Vector;
   end record;

   overriding procedure Visit_Text
     (Self : in out Annotated_Text_Builder;
      Text : VSS.Strings.Virtual_String);

   overriding procedure Enter_Emphasis
     (Self : in out Annotated_Text_Builder);

   overriding procedure Leave_Emphasis
     (Self : in out Annotated_Text_Builder);

   overriding procedure Enter_Strong
     (Self : in out Annotated_Text_Builder);

   overriding procedure Leave_Strong
     (Self : in out Annotated_Text_Builder);

   overriding procedure Enter_Code_Span
     (Self : in out Annotated_Text_Builder);

   overriding procedure Leave_Code_Span
     (Self : in out Annotated_Text_Builder);

   overriding procedure Enter_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String);

   overriding procedure Leave_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String);

   procedure Build_Annotated_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Annotations.Annotated_Text'Class);

   procedure Build_Block
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Blocks.Block);

   procedure Build_Block_Container
     (Result    : in out VSS.XML.Event_Vectors.Vector;
      Container : Markdown.Block_Containers.Block_Container'Class);

   procedure Build_Paragraph
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Blocks.Paragraphs.Paragraph);

   procedure Build_Indented_Code_Block
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Blocks.Indented_Code.Indented_Code_Block);

   procedure Build_List
     (Result : in out VSS.XML.Event_Vectors.Vector;
      List   : Markdown.Blocks.Lists.List);

   procedure Write_Start_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Tag    : VSS.Strings.Virtual_String);

   procedure Write_Start_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Tag    : VSS.Strings.Virtual_String);

   procedure Write_End_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Tag    : VSS.Strings.Virtual_String);

   procedure Write_End_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Tag    : VSS.Strings.Virtual_String);

   procedure Write_Attribute
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Name   : VSS.Strings.Virtual_String;
      Value  : VSS.Strings.Virtual_String);

   procedure Write_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Text   : VSS.Strings.Virtual_String);

   --------------------------
   -- Build_Annotated_Text --
   --------------------------

   procedure Build_Annotated_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Annotations.Annotated_Text'Class)
   is
      Visitor  : Annotated_Text_Builder;
      Iterator : Markdown.Annotations.Visitors.Annotated_Text_Iterator;

   begin
      Iterator.Iterate (Item, Visitor);

      Result.Append_Vector (Visitor.Stream);
   end Build_Annotated_Text;

   -----------------
   -- Build_Block --
   -----------------

   procedure Build_Block
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Blocks.Block) is
   begin
      if Item.Is_Paragraph then
         Build_Paragraph (Result, Item.To_Paragraph);

      elsif Item.Is_Indented_Code_Block then
         Build_Indented_Code_Block (Result, Item.To_Indented_Code_Block);

      elsif Item.Is_List then
         Build_List (Result, Item.To_List);

      else
         raise Program_Error;
      end if;
   end Build_Block;

   ---------------------------
   -- Build_Block_Container --
   ---------------------------

   procedure Build_Block_Container
     (Result    : in out VSS.XML.Event_Vectors.Vector;
      Container : Markdown.Block_Containers.Block_Container'Class) is
   begin
      for Item of Container loop
         Build_Block (Result, Item);
      end loop;
   end Build_Block_Container;

   -------------------------------
   -- Build_Indented_Code_Block --
   -------------------------------

   procedure Build_Indented_Code_Block
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Blocks.Indented_Code.Indented_Code_Block) is
   begin
      Write_Start_Element (Result, Text_Namespace, P_Element);
      Write_Attribute
        (Result,
         Text_Namespace,
         Style_Name_Attribute,
         GNATdoc_Code_Block_Style);

      for Index in Item.Text.First_Index .. Item.Text.Last_Index loop
         if Index /= Item.Text.First_Index then
            Write_Start_Element (Result, Text_Namespace, Line_Break_Element);
            Write_End_Element (Result, Text_Namespace, Line_Break_Element);
         end if;

         Write_Text (Result, Item.Text.Element (Index));
      end loop;

      Write_End_Element (Result, Text_Namespace, P_Element);
   end Build_Indented_Code_Block;

   ----------------
   -- Build_List --
   ----------------

   procedure Build_List
     (Result : in out VSS.XML.Event_Vectors.Vector;
      List   : Markdown.Blocks.Lists.List) is
   begin
      Write_Start_Element (Result, Text_Namespace, List_Element);

      if List.Is_Ordered then
         Write_Attribute
           (Result,
            Text_Namespace,
            Style_Name_Attribute,
            "GNATdoc_20_ordered_20_list");

      else
         Write_Attribute
           (Result,
            Text_Namespace,
            Style_Name_Attribute,
            "GNATdoc_20_unordered_20_list");
      end if;

      for Item of List loop
         Write_Start_Element (Result, Text_Namespace, List_Item_Element);
         Build_Block_Container (Result, Item);
         Write_End_Element (Result, Text_Namespace, List_Item_Element);
      end loop;

      Write_End_Element (Result, Text_Namespace, List_Element);
   end Build_List;

   ------------------
   -- Build_Markup --
   ------------------

   function Build_Markup
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.XML.Event_Vectors.Vector
   is
      Parser   : Markdown.Parsers.Markdown_Parser;
      Document : Markdown.Documents.Document;

   begin
      Markdown.Parsers.GNATdoc_Enable (Parser);

      for Line of Text loop
         Parser.Parse_Line (Line);
      end loop;

      Document := Parser.Document;

      return Result : VSS.XML.Event_Vectors.Vector do
         Build_Block_Container (Result, Document);
      end return;
   end Build_Markup;

   ---------------------
   -- Build_Paragraph --
   ---------------------

   procedure Build_Paragraph
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Blocks.Paragraphs.Paragraph) is
   begin
      Write_Start_Element (Result, Text_Namespace, P_Element);
      Write_Attribute
        (Result,
         Text_Namespace,
         Style_Name_Attribute,
         GNATdoc_Paragraph_Style);
      Build_Annotated_Text (Result, Item.Text);
      Write_End_Element (Result, Text_Namespace, P_Element);
   end Build_Paragraph;

   ---------------------
   -- Enter_Code_Span --
   ---------------------

   overriding procedure Enter_Code_Span
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         --  Formatting is not supported for image's alternative text

         return;
      end if;

      Write_Start_Element (Self.Stream, Text_Namespace, "span");
      Write_Attribute
        (Self.Stream,
         Text_Namespace,
         Style_Name_Attribute,
         GNATdoc_Code_Span_Style);
   end Enter_Code_Span;

   --------------------
   -- Enter_Emphasis --
   --------------------

   overriding procedure Enter_Emphasis
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         --  Formatting is not supported for image's alternative text

         return;
      end if;

      Write_Start_Element (Self.Stream, Text_Namespace, "span");
      Write_Attribute
        (Self.Stream,
         Text_Namespace,
         Style_Name_Attribute,
         "GNATdoc_20_italic");
   end Enter_Emphasis;

   -----------------
   -- Enter_Image --
   -----------------

   overriding procedure Enter_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String) is
   begin
      Self.Image := True;

      Write_Start_Element (Self.Stream, Draw_Namespace, "frame");
      Write_Start_Element (Self.Stream, Draw_Namespace, "image");
   end Enter_Image;

   ------------------
   -- Enter_Strong --
   ------------------

   overriding procedure Enter_Strong
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         --  Formatting is not supported for image's alternative text

         return;
      end if;

      Write_Start_Element (Self.Stream, Text_Namespace, "span");
      Write_Attribute
        (Self.Stream, Text_Namespace, Style_Name_Attribute, "GNATdoc_20_bold");
   end Enter_Strong;

   ---------------------
   -- Leave_Code_Span --
   ---------------------

   overriding procedure Leave_Code_Span
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         --  Formatting is not supported for image's alternative text

         return;
      end if;

      Write_End_Element (Self.Stream, Text_Namespace, "span");
   end Leave_Code_Span;

   --------------------
   -- Leave_Emphasis --
   --------------------

   overriding procedure Leave_Emphasis
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         --  Formatting is not supported for image's alternative text

         return;
      end if;

      Write_End_Element (Self.Stream, Text_Namespace, "span");
   end Leave_Emphasis;

   -----------------
   -- Leave_Image --
   -----------------

   overriding procedure Leave_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String) is
   begin
      Write_End_Element (Self.Stream, Draw_Namespace, "image");
      Write_End_Element (Self.Stream, Draw_Namespace, "frame");

      Self.Image := False;
      Self.Text.Clear;
   end Leave_Image;

   ------------------
   -- Leave_Strong --
   ------------------

   overriding procedure Leave_Strong
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         --  Formatting is not supported for image's alternative text

         return;
      end if;

      Write_End_Element (Self.Stream, Text_Namespace, "span");
   end Leave_Strong;

   ----------------
   -- Visit_Text --
   ----------------

   overriding procedure Visit_Text
     (Self : in out Annotated_Text_Builder;
      Text : VSS.Strings.Virtual_String) is
   begin
      if Self.Image then
         Self.Text.Append (Text);
         --  ???

      else
         Write_Text (Self.Stream, Text);
      end if;
   end Visit_Text;

   ---------------------
   -- Write_Attribute --
   ---------------------

   procedure Write_Attribute
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Name   : VSS.Strings.Virtual_String;
      Value  : VSS.Strings.Virtual_String) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (Kind  => VSS.XML.Events.Attribute,
            URI   => URI,
            Name  => Name,
            Value => Value));
   end Write_Attribute;

   -----------------------
   -- Write_End_Element --
   -----------------------

   procedure Write_End_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Tag    : VSS.Strings.Virtual_String) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (VSS.XML.Events.End_Element,
            VSS.XML.Namespaces.HTML_Namespace,
            Tag));
   end Write_End_Element;

   -----------------------
   -- Write_End_Element --
   -----------------------

   procedure Write_End_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Tag    : VSS.Strings.Virtual_String) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (VSS.XML.Events.End_Element,
            URI,
            Tag));
   end Write_End_Element;

   -------------------------
   -- Write_Start_Element --
   -------------------------

   procedure Write_Start_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Tag    : VSS.Strings.Virtual_String) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (VSS.XML.Events.Start_Element,
            VSS.XML.Namespaces.HTML_Namespace,
            Tag));
   end Write_Start_Element;

   -------------------------
   -- Write_Start_Element --
   -------------------------

   procedure Write_Start_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Tag    : VSS.Strings.Virtual_String) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (VSS.XML.Events.Start_Element,
            URI,
            Tag));
   end Write_Start_Element;

   ----------------
   -- Write_Text --
   ----------------

   procedure Write_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Text   : VSS.Strings.Virtual_String) is
   begin
      Result.Append (VSS.XML.Events.XML_Event'(VSS.XML.Events.Text, Text));
   end Write_Text;

end GNATdoc.Backend.ODF_Markup;
