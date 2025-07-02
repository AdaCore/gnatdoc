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

with VSS.IRIs;
with VSS.XML.Events;
with VSS.XML.Namespaces;

with Markdown.Attribute_Lists;
with Markdown.Inlines.Visitors;
with Markdown.Block_Containers;
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Documents;
with Markdown.Parsers.GNATdoc_Enable;

package body GNATdoc.Backend.HTML_Markup is

   type Annotated_Text_Builder is
     limited new Markdown.Inlines.Visitors.Annotated_Text_Visitor with
   record
      Image  : Boolean := False;
      Text   : VSS.Strings.Virtual_String;
      Stream : VSS.XML.Event_Vectors.Vector;
   end record;

   overriding procedure Visit_Text
     (Self : in out Annotated_Text_Builder;
      Text : VSS.Strings.Virtual_String);

   overriding procedure Visit_Soft_Line_Break
     (Self : in out Annotated_Text_Builder);

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
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List);

   overriding procedure Leave_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List);

   procedure Build_Annotated_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Inlines.Inline_Vector'Class);

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

   procedure Write_Attribute
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Name   : VSS.Strings.Virtual_String;
      Value  : VSS.Strings.Virtual_String);

   procedure Write_Attribute
     (Result : in out VSS.XML.Event_Vectors.Vector;
      URI    : VSS.IRIs.IRI;
      Name   : VSS.Strings.Virtual_String;
      Value  : VSS.Strings.Virtual_String);

   procedure Write_End_Element
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Tag    : VSS.Strings.Virtual_String);

   procedure Write_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Text   : VSS.Strings.Virtual_String);

   procedure Write_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Text   : VSS.String_Vectors.Virtual_String_Vector);

   --------------------------
   -- Build_Annotated_Text --
   --------------------------

   procedure Build_Annotated_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Item   : Markdown.Inlines.Inline_Vector'Class)
   is
      Visitor  : Annotated_Text_Builder;
      Iterator : Markdown.Inlines.Visitors.Annotated_Text_Iterator;

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
      Write_Start_Element (Result, "pre");
      Write_Start_Element (Result, "code");
      Write_Attribute
        (Result, VSS.XML.Namespaces.XML_Namespace, "space", "preserve");
      Write_Text (Result, Item.Text);
      Write_End_Element (Result, "code");
      Write_End_Element (Result, "pre");
   end Build_Indented_Code_Block;

   ----------------
   -- Build_List --
   ----------------

   procedure Build_List
     (Result : in out VSS.XML.Event_Vectors.Vector;
      List   : Markdown.Blocks.Lists.List) is
   begin
      if List.Is_Ordered then
         Write_Start_Element (Result, "ol");
      else
         Write_Start_Element (Result, "ul");
      end if;

      for Item of List loop
         Write_Start_Element (Result, "li");
         Build_Block_Container (Result, Item);
         Write_End_Element (Result, "li");
      end loop;

      if List.Is_Ordered then
         Write_End_Element (Result, "ol");
      else
         Write_End_Element (Result, "ul");
      end if;
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
      Write_Start_Element (Result, "p");
      Build_Annotated_Text (Result, Item.Text);
      Write_End_Element (Result, "p");
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

      Write_Start_Element (Self.Stream, "code");
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

      Write_Start_Element (Self.Stream, "em");
   end Enter_Emphasis;

   -----------------
   -- Enter_Image --
   -----------------

   overriding procedure Enter_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List) is
   begin
      Self.Image := True;
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

      Write_Start_Element (Self.Stream, "strong");
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

      Write_End_Element (Self.Stream, "code");
   end Leave_Code_Span;

   -----------------
   -- Leave_Image --
   -----------------

   overriding procedure Leave_Image
     (Self        : in out Annotated_Text_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List)
   is
      use type VSS.Strings.Virtual_String;

   begin
      Write_Start_Element (Self.Stream, "img");
      Write_Attribute (Self.Stream, "src", "images/" & Destination);

      if not Title.Is_Empty then
         Write_Attribute (Self.Stream, "title", Title);
      end if;

      if not Self.Text.Is_Empty then
         Write_Attribute (Self.Stream, "alt", Self.Text);
      end if;

      for J in 1 .. Attributes.Length loop
         if Attributes.Name (J) = "width" then
            Write_Attribute (Self.Stream, "width", Attributes.Value (J));

         elsif Attributes.Name (J) = "height" then
            Write_Attribute (Self.Stream, "height", Attributes.Value (J));
         end if;
      end loop;

      Write_End_Element (Self.Stream, "img");

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

      Write_End_Element (Self.Stream, "strong");
   end Leave_Strong;

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

      Write_End_Element (Self.Stream, "em");
   end Leave_Emphasis;

   ---------------------------
   -- Visit_Soft_Line_Break --
   ---------------------------

   overriding procedure Visit_Soft_Line_Break
     (Self : in out Annotated_Text_Builder) is
   begin
      --  Convert soft line break into space character.

      Self.Visit_Text (" ");
   end Visit_Soft_Line_Break;

   ----------------
   -- Visit_Text --
   ----------------

   overriding procedure Visit_Text
     (Self : in out Annotated_Text_Builder;
      Text : VSS.Strings.Virtual_String) is
   begin
      if Self.Image then
         Self.Text.Append (Text);

      else
         Write_Text (Self.Stream, Text);
      end if;
   end Visit_Text;

   ---------------------
   -- Write_Attribute --
   ---------------------

   procedure Write_Attribute
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Name   : VSS.Strings.Virtual_String;
      Value  : VSS.Strings.Virtual_String) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (Kind  => VSS.XML.Events.Attribute,
            URI   => <>,
            Name  => Name,
            Value => Value));
   end Write_Attribute;

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

   ----------------
   -- Write_Text --
   ----------------

   procedure Write_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Text   : VSS.Strings.Virtual_String) is
   begin
      Result.Append (VSS.XML.Events.XML_Event'(VSS.XML.Events.Text, Text));
   end Write_Text;

   ----------------
   -- Write_Text --
   ----------------

   procedure Write_Text
     (Result : in out VSS.XML.Event_Vectors.Vector;
      Text   : VSS.String_Vectors.Virtual_String_Vector) is
   begin
      Result.Append
        (VSS.XML.Events.XML_Event'
           (VSS.XML.Events.Text, Text.Join_Lines (VSS.Strings.LF)));
   end Write_Text;

end GNATdoc.Backend.HTML_Markup;
