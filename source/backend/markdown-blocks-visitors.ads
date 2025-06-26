--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Markdown.Documents;
with Markdown.List_Items;

package Markdown.Blocks.Visitors
  with Preelaborate
is

   type Block_Visitor is limited interface;

   not overriding procedure Enter_Indented_Code_Block
     (Self  : in out Block_Visitor;
      Block : Markdown.Blocks.Indented_Code.Indented_Code_Block'Class) is null;

   not overriding procedure Leave_Indented_Code_Block
     (Self  : in out Block_Visitor;
      Block : Markdown.Blocks.Indented_Code.Indented_Code_Block'Class) is null;

   not overriding procedure Enter_List
     (Self  : in out Block_Visitor;
      Block : Markdown.Blocks.Lists.List'Class) is null;

   not overriding procedure Leave_List
     (Self  : in out Block_Visitor;
      Block : Markdown.Blocks.Lists.List'Class) is null;

   not overriding procedure Enter_List_Item
     (Self      : in out Block_Visitor;
      Container : Markdown.List_Items.List_Item'Class) is null;

   not overriding procedure Leave_List_Item
     (Self      : in out Block_Visitor;
      Container : Markdown.List_Items.List_Item'Class'Class) is null;

   not overriding procedure Enter_Paragraph
     (Self  : in out Block_Visitor;
      Block : Markdown.Blocks.Paragraphs.Paragraph'Class) is null;

   not overriding procedure Leave_Paragraph
     (Self  : in out Block_Visitor;
      Block : Markdown.Blocks.Paragraphs.Paragraph'Class) is null;

   type Block_Iterator is tagged limited private;

   procedure Iterate
     (Self     : in out Block_Iterator'Class;
      Document : Markdown.Documents.Document'Class;
      Visitor  : in out Block_Visitor'Class);

private

   type Block_Iterator is tagged limited null record;

end Markdown.Blocks.Visitors;
