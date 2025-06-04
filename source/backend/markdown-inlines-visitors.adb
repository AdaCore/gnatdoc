--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body Markdown.Inlines.Visitors is

   -------------
   -- Iterate --
   -------------

   procedure Iterate
     (Self    : in out Annotated_Text_Iterator'Class;
      Text    : Markdown.Inlines.Inline_Vector'Class;
      Visitor : in out Annotated_Text_Visitor'Class)
   is
      pragma Unreferenced (Self);

      type Iteration_State is record
         Destination : VSS.Strings.Virtual_String;
         --  Link/image url
         Title       : VSS.Strings.Virtual_String;
         --  Link/image title
         Attributes  : Markdown.Attribute_Lists.Attribute_List;
         --  Link/image attributes if Link_Attributes extension is on
      end record;
      --  Suppose we don't have nested images for now.

      procedure Iterate
        (State : in out Iteration_State;
         Item  : Markdown.Inlines.Inline);

      -------------
      -- Iterate --
      -------------

      procedure Iterate
        (State : in out Iteration_State;
         Item  : Markdown.Inlines.Inline)
      is

         Ignore : Boolean;

      begin
         case Item.Kind is
            when Markdown.Inlines.Text =>
               Visitor.Visit_Text (Item.Text);

            when Markdown.Inlines.Start_Emphasis =>
               Visitor.Enter_Emphasis;

            when Markdown.Inlines.End_Emphasis =>
               Visitor.Leave_Emphasis;

            when Markdown.Inlines.Start_Strong =>
               Visitor.Enter_Strong;

            when Markdown.Inlines.End_Strong =>
               Visitor.Leave_Strong;

            when Markdown.Inlines.Code_Span =>
               Visitor.Enter_Code_Span;
               Visitor.Visit_Text (Item.Code_Span);
               Visitor.Leave_Code_Span;

            when Markdown.Inlines.Start_Image =>
               State :=
                 (Destination => Item.Destination,
                  Title       => Item.Title.Join_Lines (VSS.Strings.LF),
                  Attributes  => Item.Attributes);

               Visitor.Enter_Image
                 (Destination => State.Destination,
                  Title       => State.Title);

            when Markdown.Inlines.End_Image =>
               Visitor.Leave_Image
                 (Destination => State.Destination,
                  Title       => State.Title);

            when others =>
               null;
         end case;
      end Iterate;

      State : Iteration_State;
   begin
      for Item of Text loop
         Iterate (State, Item);
      end loop;
   end Iterate;

end Markdown.Inlines.Visitors;
