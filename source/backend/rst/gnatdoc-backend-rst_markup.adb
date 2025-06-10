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

with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with Markdown.Attribute_Lists;
with Markdown.Inlines.Visitors;
with Markdown.Block_Containers;
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Documents;
with Markdown.Parsers.GNATdoc_Enable;

package body GNATdoc.Backend.RST_Markup is

   type Annotated_Text_Builder is
     limited new Markdown.Inlines.Visitors.Annotated_Text_Visitor with
   record
      Image  : Boolean := False;
      Text   : VSS.Strings.Virtual_String;
      Output : VSS.String_Vectors.Virtual_String_Vector;
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
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Inlines.Inline_Vector'Class);

   procedure Build_Block
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Blocks.Block);

   procedure Build_Block_Container
     (Output    : in out VSS.String_Vectors.Virtual_String_Vector;
      Container : Markdown.Block_Containers.Block_Container'Class);

   procedure Build_Paragraph
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Blocks.Paragraphs.Paragraph);

   procedure Build_Indented_Code_Block
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Blocks.Indented_Code.Indented_Code_Block);

   procedure Build_List
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      List   : Markdown.Blocks.Lists.List);

   procedure Write_Text
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Text   : VSS.Strings.Virtual_String);

   --------------------------
   -- Build_Annotated_Text --
   --------------------------

   procedure Build_Annotated_Text
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Inlines.Inline_Vector'Class)
   is
      Visitor  : Annotated_Text_Builder;
      Iterator : Markdown.Inlines.Visitors.Annotated_Text_Iterator;

   begin
      Visitor.Output.Append (VSS.Strings.Empty_Virtual_String);
      Iterator.Iterate (Item, Visitor);

      Output.Append (Visitor.Output);
   end Build_Annotated_Text;

   -----------------
   -- Build_Block --
   -----------------

   procedure Build_Block
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Blocks.Block) is
   begin
      Output.Append (VSS.Strings.Empty_Virtual_String);

      if Item.Is_Paragraph then
         Build_Paragraph (Output, Item.To_Paragraph);

      elsif Item.Is_Indented_Code_Block then
         Build_Indented_Code_Block (Output, Item.To_Indented_Code_Block);

      elsif Item.Is_List then
         Build_List (Output, Item.To_List);

      else
         raise Program_Error;
      end if;
   end Build_Block;

   ---------------------------
   -- Build_Block_Container --
   ---------------------------

   procedure Build_Block_Container
     (Output    : in out VSS.String_Vectors.Virtual_String_Vector;
      Container : Markdown.Block_Containers.Block_Container'Class) is
   begin
      for Item of Container loop
         Build_Block (Output, Item);
      end loop;
   end Build_Block_Container;

   -------------------------------
   -- Build_Indented_Code_Block --
   -------------------------------

   procedure Build_Indented_Code_Block
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Blocks.Indented_Code.Indented_Code_Block)
   is
      use type VSS.Strings.Virtual_String;

   begin
      Output.Append ("..  code-block:: ada");
      Output.Append (VSS.Strings.Empty_Virtual_String);

      for Line of Item.Text loop
         Output.Append ("    " & Line);
      end loop;

      Output.Append (VSS.Strings.Empty_Virtual_String);
      Output.Append (VSS.Strings.Empty_Virtual_String);
   end Build_Indented_Code_Block;

   ----------------
   -- Build_List --
   ----------------

   procedure Build_List
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      List   : Markdown.Blocks.Lists.List) is
   begin
      for Item of List loop
         if List.Is_Ordered then
            Write_Text (Output, "# ");

         else
            Write_Text (Output, "* ");
         end if;

         Build_Block_Container (Output, Item);
      end loop;
   end Build_List;

   ------------------
   -- Build_Markup --
   ------------------

   function Build_Markup
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Parser   : Markdown.Parsers.Markdown_Parser;
      Document : Markdown.Documents.Document;

   begin
      Markdown.Parsers.GNATdoc_Enable (Parser);
      Parser.Set_Extensions ((Link_Attributes => True));

      for Line of Text loop
         Parser.Parse_Line (Line);
      end loop;

      Document := Parser.Document;

      return Result : VSS.String_Vectors.Virtual_String_Vector do
         Build_Block_Container (Result, Document);
      end return;
   end Build_Markup;

   ---------------------
   -- Build_Paragraph --
   ---------------------

   procedure Build_Paragraph
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Item   : Markdown.Blocks.Paragraphs.Paragraph) is
   begin
      Build_Annotated_Text (Output, Item.Text);
   end Build_Paragraph;

   ---------------------
   -- Enter_Code_Span --
   ---------------------

   overriding procedure Enter_Code_Span
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Write_Text (Self.Output, "``");
   end Enter_Code_Span;

   --------------------
   -- Enter_Emphasis --
   --------------------

   overriding procedure Enter_Emphasis
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Write_Text (Self.Output, "*");
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
         return;
      end if;

      Write_Text (Self.Output, "**");
   end Enter_Strong;

   ---------------------
   -- Leave_Code_Span --
   ---------------------

   overriding procedure Leave_Code_Span
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Write_Text (Self.Output, "``");
   end Leave_Code_Span;

   --------------------
   -- Leave_Emphasis --
   --------------------

   overriding procedure Leave_Emphasis
     (Self : in out Annotated_Text_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Write_Text (Self.Output, "*");
   end Leave_Emphasis;

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

      Image_Template  : VSS.Strings.Templates.Virtual_String_Template :=
        "..  image:: {}";
      Width_Template  : VSS.Strings.Templates.Virtual_String_Template :=
        "    :width: {}";
      Height_Template : VSS.Strings.Templates.Virtual_String_Template :=
        "    :height: {}";
      Alt_Template    : VSS.Strings.Templates.Virtual_String_Template :=
        "    :alt: {}";

   begin
      Self.Output.Append
        (Image_Template.Format
           (VSS.Strings.Formatters.Strings.Image (Destination)));

      for Attribute of Attributes loop
         if Attribute.Name = "width" then
            Self.Output.Append
              (Width_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Attribute.Value)));

         elsif Attribute.Name = "height" then
            Self.Output.Append
              (Height_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Attribute.Value)));
         end if;
      end loop;

      if not Self.Text.Is_Empty then
         Self.Output.Append
           (Alt_Template.Format
              (VSS.Strings.Formatters.Strings.Image (Self.Text)));
      end if;

      Self.Output.Append (VSS.Strings.Empty_Virtual_String);

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
         return;
      end if;

      Write_Text (Self.Output, "**");
   end Leave_Strong;

   ---------------------------
   -- Visit_Soft_Line_Break --
   ---------------------------

   overriding procedure Visit_Soft_Line_Break
     (Self : in out Annotated_Text_Builder) is
   begin
      Self.Output.Append (VSS.Strings.Empty_Virtual_String);
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

         return;
      end if;

      Write_Text (Self.Output, Text);
   end Visit_Text;

   ----------------
   -- Write_Text --
   ----------------

   procedure Write_Text
     (Output : in out VSS.String_Vectors.Virtual_String_Vector;
      Text   : VSS.Strings.Virtual_String)
   is
      Line : VSS.Strings.Virtual_String := Output.Last_Element;

   begin
      Line.Append (Text);
      Output.Replace (Output.Last_Index, Line);
   end Write_Text;

end GNATdoc.Backend.RST_Markup;
