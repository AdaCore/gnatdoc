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
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Paragraphs;
with Markdown.Blocks.Visitors;
with Markdown.List_Items;
with Markdown.Parsers.GNATdoc_Enable;

package body GNATdoc.Backend.RST_Markup is

   type RST_Markup_Builder is
     limited new Markdown.Blocks.Visitors.Block_Visitor
       and Markdown.Inlines.Visitors.Annotated_Text_Visitor
   with record
      Output : VSS.String_Vectors.Virtual_String_Vector;

      Image  : Boolean := False;
      Text   : VSS.Strings.Virtual_String;
   end record;

   overriding procedure Enter_Indented_Code_Block
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Indented_Code.Indented_Code_Block'Class);

   overriding procedure Leave_Indented_Code_Block
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Indented_Code.Indented_Code_Block'Class);

   overriding procedure Enter_List_Item
     (Self      : in out RST_Markup_Builder;
      Container : Markdown.List_Items.List_Item'Class);

   overriding procedure Enter_Paragraph
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Paragraphs.Paragraph'Class);

   overriding procedure Leave_Paragraph
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Paragraphs.Paragraph'Class);

   overriding procedure Visit_Text
     (Self : in out RST_Markup_Builder;
      Text : VSS.Strings.Virtual_String);

   overriding procedure Visit_Soft_Line_Break
     (Self : in out RST_Markup_Builder);

   overriding procedure Enter_Emphasis (Self : in out RST_Markup_Builder);

   overriding procedure Leave_Emphasis (Self : in out RST_Markup_Builder);

   overriding procedure Enter_Strong (Self : in out RST_Markup_Builder);

   overriding procedure Leave_Strong (Self : in out RST_Markup_Builder);

   overriding procedure Enter_Code_Span (Self : in out RST_Markup_Builder);

   overriding procedure Leave_Code_Span (Self : in out RST_Markup_Builder);

   overriding procedure Enter_Image
     (Self        : in out RST_Markup_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List);

   overriding procedure Leave_Image
     (Self        : in out RST_Markup_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List);

   procedure Write
     (Self : in out RST_Markup_Builder'Class;
      Text : VSS.Strings.Virtual_String);

   procedure Write_Line
     (Self : in out RST_Markup_Builder'Class;
      Text : VSS.Strings.Virtual_String);

   procedure Write_New_Line (Self : in out RST_Markup_Builder'Class);

   ------------------
   -- Build_Markup --
   ------------------

   function Build_Markup
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Parser   : Markdown.Parsers.Markdown_Parser;
      Builder  : RST_Markup_Builder;
      Iterator : Markdown.Blocks.Visitors.Block_Iterator;

   begin
      Markdown.Parsers.GNATdoc_Enable (Parser);
      Parser.Set_Extensions ((Link_Attributes => True));

      for Line of Text loop
         Parser.Parse_Line (Line);
      end loop;

      Builder.Write_New_Line;
      Iterator.Iterate (Parser.Document, Builder);

      return Builder.Output;
   end Build_Markup;

   ---------------------
   -- Enter_Code_Span --
   ---------------------

   overriding procedure Enter_Code_Span (Self : in out RST_Markup_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Self.Write ("``");
   end Enter_Code_Span;

   --------------------
   -- Enter_Emphasis --
   --------------------

   overriding procedure Enter_Emphasis (Self : in out RST_Markup_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Self.Write ("*");
   end Enter_Emphasis;

   -----------------
   -- Enter_Image --
   -----------------

   overriding procedure Enter_Image
     (Self        : in out RST_Markup_Builder;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String;
      Attributes  : Markdown.Attribute_Lists.Attribute_List) is
   begin
      Self.Image := True;
   end Enter_Image;

   -------------------------------
   -- Enter_Indented_Code_Block --
   -------------------------------

   overriding procedure Enter_Indented_Code_Block
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Indented_Code.Indented_Code_Block'Class)
   is
      use type VSS.Strings.Virtual_String;

   begin
      Self.Write_Line ("..  code-block:: ada");
      Self.Write_New_Line;

      for Line of Block.Text loop
         Self.Write_Line ("    " & Line);
      end loop;
   end Enter_Indented_Code_Block;

   ---------------------
   -- Enter_List_Item --
   ---------------------

   overriding procedure Enter_List_Item
     (Self      : in out RST_Markup_Builder;
      Container : Markdown.List_Items.List_Item'Class) is
   begin
      if Container.Is_Ordered then
         Self.Write ("#. ");

      else
         Self.Write ("* ");
      end if;
   end Enter_List_Item;

   ---------------------
   -- Enter_Paragraph --
   ---------------------

   overriding procedure Enter_Paragraph
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Paragraphs.Paragraph'Class)
   is
      Iterator : Markdown.Inlines.Visitors.Annotated_Text_Iterator;

   begin
      Iterator.Iterate (Block.Text, Self);
   end Enter_Paragraph;

   ------------------
   -- Enter_Strong --
   ------------------

   overriding procedure Enter_Strong
     (Self : in out RST_Markup_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Self.Write ("**");
   end Enter_Strong;

   ---------------------
   -- Leave_Code_Span --
   ---------------------

   overriding procedure Leave_Code_Span
     (Self : in out RST_Markup_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Self.Write ("``");
   end Leave_Code_Span;

   --------------------
   -- Leave_Emphasis --
   --------------------

   overriding procedure Leave_Emphasis
     (Self : in out RST_Markup_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Self.Write ("*");
   end Leave_Emphasis;

   -----------------
   -- Leave_Image --
   -----------------

   overriding procedure Leave_Image
     (Self        : in out RST_Markup_Builder;
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
      Self.Write_Line
        (Image_Template.Format
           (VSS.Strings.Formatters.Strings.Image (Destination)));

      for Attribute of Attributes loop
         if Attribute.Name = "width" then
            Self.Write_Line
              (Width_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Attribute.Value)));

         elsif Attribute.Name = "height" then
            Self.Write_Line
              (Height_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Attribute.Value)));
         end if;
      end loop;

      if not Self.Text.Is_Empty then
         Self.Write_Line
           (Alt_Template.Format
              (VSS.Strings.Formatters.Strings.Image (Self.Text)));
      end if;

      Self.Image := False;
      Self.Text.Clear;
   end Leave_Image;

   -------------------------------
   -- Leave_Indented_Code_Block --
   -------------------------------

   overriding procedure Leave_Indented_Code_Block
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Indented_Code.Indented_Code_Block'Class) is
   begin
      Self.Write_New_Line;
   end Leave_Indented_Code_Block;

   ---------------------
   -- Leave_Paragraph --
   ---------------------

   overriding procedure Leave_Paragraph
     (Self  : in out RST_Markup_Builder;
      Block : Markdown.Blocks.Paragraphs.Paragraph'Class) is
   begin
      Self.Write_New_Line;
      Self.Write_New_Line;
   end Leave_Paragraph;

   ------------------
   -- Leave_Strong --
   ------------------

   overriding procedure Leave_Strong
     (Self : in out RST_Markup_Builder) is
   begin
      if Self.Image then
         return;
      end if;

      Self.Write ("**");
   end Leave_Strong;

   ---------------------------
   -- Visit_Soft_Line_Break --
   ---------------------------

   overriding procedure Visit_Soft_Line_Break
     (Self : in out RST_Markup_Builder) is
   begin
      Self.Write_New_Line;
   end Visit_Soft_Line_Break;

   ----------------
   -- Visit_Text --
   ----------------

   overriding procedure Visit_Text
     (Self : in out RST_Markup_Builder;
      Text : VSS.Strings.Virtual_String) is
   begin
      if Self.Image then
         --  Self.Text.Append (Text);

         return;
      end if;

      Self.Write (Text);
   end Visit_Text;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self : in out RST_Markup_Builder'Class;
      Text : VSS.Strings.Virtual_String)
   is
      Line : VSS.Strings.Virtual_String := Self.Output.Last_Element;

   begin
      Line.Append (Text);
      Self.Output.Replace (Self.Output.Last_Index, Line);
   end Write;

   --------------------
   -- Write_New_Line --
   --------------------

   procedure Write_New_Line (Self : in out RST_Markup_Builder'Class) is
   begin
      Self.Output.Append (VSS.Strings.Empty_Virtual_String);
   end Write_New_Line;

   ----------------
   -- Write_Line --
   ----------------

   procedure Write_Line
     (Self : in out RST_Markup_Builder'Class;
      Text : VSS.Strings.Virtual_String) is
   begin
      Self.Write (Text);
      Self.Write_New_Line;
   end Write_Line;

end GNATdoc.Backend.RST_Markup;
