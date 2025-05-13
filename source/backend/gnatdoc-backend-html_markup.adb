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

with VSS.Strings.Character_Iterators;
with VSS.XML.Events;
with VSS.XML.Namespaces;

with Markdown.Annotations;
with Markdown.Block_Containers;
with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Documents;
with Markdown.Parsers.GNATdoc_Enable;

package body GNATdoc.Backend.HTML_Markup is

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

   procedure Write_Attribute
     (Result : in out VSS.XML.Event_Vectors.Vector;
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
      Item   : Markdown.Annotations.Annotated_Text'Class)
   is
      use type VSS.Strings.Character_Count;

      procedure Build_Annotation
        (From  : in out Positive;
         Next  : in out VSS.Strings.Character_Iterators.Character_Iterator;
         Limit : VSS.Strings.Character_Count);
      --  From is an index in Text.Annotation to start from
      --  Next is a not printed yet character in Text.Plain_Text
      --  Dont go after Limit position in Text.Plain_Text

      ----------------------
      -- Build_Annotation --
      ----------------------

      procedure Build_Annotation
        (From  : in out Positive;
         Next  : in out VSS.Strings.Character_Iterators.Character_Iterator;
         Limit : VSS.Strings.Character_Count)
      is
         function Before
           (From : VSS.Strings.Character_Index)
              return VSS.Strings.Character_Iterators.Character_Iterator;

         function After
           (Index : VSS.Strings.Character_Index)
              return VSS.Strings.Character_Iterators.Character_Iterator;

         -----------
         -- After --
         -----------

         function After
           (Index : VSS.Strings.Character_Index)
              return VSS.Strings.Character_Iterators.Character_Iterator is
         begin
            return Iter : VSS.Strings.Character_Iterators.Character_Iterator do
               Iter.Set_At (Next);

               while Iter.Character_Index > Index and then Iter.Backward loop
                  null;
               end loop;

               while Iter.Character_Index <= Index and then Iter.Forward loop
                  null;
               end loop;
            end return;
         end After;

         ------------
         -- Before --
         ------------

         function Before
           (From : VSS.Strings.Character_Index)
            return VSS.Strings.Character_Iterators.Character_Iterator is
         begin
            return Iter : VSS.Strings.Character_Iterators.Character_Iterator do
               Iter.Set_At (Next);

               while Iter.Character_Index >= From and then Iter.Backward loop
                  null;
               end loop;

               while Iter.Character_Index + 1 < From and then Iter.Forward loop
                  null;
               end loop;
            end return;
         end Before;

         Ignore : Boolean;

      begin
         while From <= Item.Annotation.Last_Index and then
           Item.Annotation (From).To <= Limit
         loop
            declare
               use type VSS.Strings.Virtual_String;

               Annotation : constant Markdown.Annotations.Annotation :=
                 Item.Annotation (From);
               Last       : constant
                 VSS.Strings.Character_Iterators.Character_Iterator :=
                   Before (Annotation.From);

            begin
               From := From + 1;

               Write_Text (Result, Item.Plain_Text.Slice (Next, Last));

               Next.Set_At (Last);
               Ignore := Next.Forward;

               case Annotation.Kind is
                  when Markdown.Annotations.Emphasis =>
                     Write_Start_Element (Result, "em");
                     Build_Annotation (From, Next, Annotation.To);
                     Write_End_Element (Result, "em");

                  when Markdown.Annotations.Strong =>
                     Write_Start_Element (Result, "strong");
                     Build_Annotation (From, Next, Annotation.To);
                     Write_End_Element (Result, "strong");

                  when Markdown.Annotations.Code_Span =>
                     Write_Start_Element (Result, "code");
                     Build_Annotation (From, Next, Annotation.To);
                     Write_End_Element (Result, "code");

                  when Markdown.Annotations.Image =>
                     Write_Start_Element (Result, "img");
                     Write_Attribute
                       (Result, "src", "images/" & Annotation.Destination);
                     Write_End_Element (Result, "img");

                     Next.Set_At (After (Annotation.To));
                     --  Skip annotated text inside image inline.

                  when others =>
                     null;
               end case;
            end;
         end loop;

         if Next.Character_Index <= Limit then
            declare
               Last : constant
                 VSS.Strings.Character_Iterators.Character_Iterator :=
                   Before (Limit + 1);

            begin
               Write_Text (Result, Item.Plain_Text.Slice (Next, Last));

               Next.Set_At (Last);
               Ignore := Next.Forward;
            end;
         end if;
      end Build_Annotation;

      From  : Positive := Item.Annotation.First_Index;
      Next  : VSS.Strings.Character_Iterators.Character_Iterator :=
        Item.Plain_Text.At_First_Character;

   begin
      Build_Annotation
        (From  => From,
         Next  => Next,
         Limit => Item.Plain_Text.Character_Length);
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
