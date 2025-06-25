--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Blocks.Indented_Code;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Block_Containers;

package body Markdown.Blocks.Visitors is

   procedure Visit_Block_Container
     (Self      : in out Block_Iterator'Class;
      Container : Markdown.Block_Containers.Block_Container'Class;
      Visitor   : in out Block_Visitor'Class);

   procedure Visit_List
     (Self    : in out Block_Iterator'Class;
      Block   : Markdown.Blocks.Lists.List'Class;
      Visitor : in out Block_Visitor'Class);

   -------------
   -- Iterate --
   -------------

   procedure Iterate
     (Self     : in out Block_Iterator'Class;
      Document : Markdown.Documents.Document'Class;
      Visitor  : in out Block_Visitor'Class) is
   begin
      Self.Visit_Block_Container (Document, Visitor);
   end Iterate;

   ---------------------------
   -- Visit_Block_Container --
   ---------------------------

   procedure Visit_Block_Container
     (Self      : in out Block_Iterator'Class;
      Container : Markdown.Block_Containers.Block_Container'Class;
      Visitor   : in out Block_Visitor'Class) is
   begin
      for Item of Container loop
         if Item.Is_Paragraph then
            Visitor.Enter_Paragraph (Item.To_Paragraph);
            Visitor.Leave_Paragraph (Item.To_Paragraph);

         elsif Item.Is_Indented_Code_Block then
            Visitor.Enter_Indented_Code_Block (Item.To_Indented_Code_Block);
            Visitor.Leave_Indented_Code_Block (Item.To_Indented_Code_Block);

         elsif Item.Is_List then
            Self.Visit_List (Item.To_List, Visitor);

         else
            raise Program_Error;
         end if;
      end loop;
   end Visit_Block_Container;

   ----------------
   -- Visit_List --
   ----------------

   procedure Visit_List
     (Self    : in out Block_Iterator'Class;
      Block   : Markdown.Blocks.Lists.List'Class;
      Visitor : in out Block_Visitor'Class) is
   begin
      Visitor.Enter_List (Block);

      for Item of Block loop
         Visitor.Enter_List_Item (Item);

         Self.Visit_Block_Container (Item, Visitor);

         Visitor.Leave_List_Item (Item);
      end loop;

      Visitor.Leave_List (Block);
   end Visit_List;

end Markdown.Blocks.Visitors;
