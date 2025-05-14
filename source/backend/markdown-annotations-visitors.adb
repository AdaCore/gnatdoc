--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with VSS.Strings.Character_Iterators;

package body Markdown.Annotations.Visitors is

   -------------
   -- Iterate --
   -------------

   procedure Iterate
     (Self    : in out Annotated_Text_Iterator'Class;
      Text    : Markdown.Annotations.Annotated_Text'Class;
      Visitor : in out Annotated_Text_Visitor'Class)
   is
      pragma Unreferenced (Self);

      procedure Iterate
        (Index : in out Positive;
         Next  : in out VSS.Strings.Character_Iterators.Character_Iterator;
         Limit : VSS.Strings.Character_Count);
      --  Index is an index in Text.Annotation to start from
      --  Next is a not printed yet character in Text.Plain_Text
      --  Dont go after Limit position in Text.Plain_Text

      -------------
      -- Iterate --
      -------------

      procedure Iterate
        (Index : in out Positive;
         Next  : in out VSS.Strings.Character_Iterators.Character_Iterator;
         Limit : VSS.Strings.Character_Count)
      is
         use type VSS.Strings.Character_Count;

         function Before
           (From : VSS.Strings.Character_Index)
              return VSS.Strings.Character_Iterators.Character_Iterator;

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
         while Index <= Text.Annotation.Last_Index
           and then Text.Annotation (Index).To <= Limit
         loop
            declare
               Annotation : constant Markdown.Annotations.Annotation :=
                 Text.Annotation (Index);
               Last       : constant
                 VSS.Strings.Character_Iterators.Character_Iterator :=
                   Before (Annotation.From);

            begin
               Index := @ + 1;

               Visitor.Visit_Text (Text.Plain_Text.Slice (Next, Last));

               Next.Set_At (Last);
               Ignore := Next.Forward;

               case Annotation.Kind is
                  when Markdown.Annotations.Emphasis =>
                     Visitor.Enter_Emphasis;
                     Iterate (Index, Next, Annotation.To);
                     Visitor.Leave_Emphasis;

                  when Markdown.Annotations.Strong =>
                     Visitor.Enter_Strong;
                     Iterate (Index, Next, Annotation.To);
                     Visitor.Leave_Strong;

                  when Markdown.Annotations.Code_Span =>
                     Visitor.Enter_Code_Span;
                     Iterate (Index, Next, Annotation.To);
                     Visitor.Leave_Code_Span;

                  when Markdown.Annotations.Image =>
                     Visitor.Enter_Image
                       (Destination => Annotation.Destination,
                        Title       =>
                           Annotation.Title.Join_Lines (VSS.Strings.LF));
                     Iterate (Index, Next, Annotation.To);
                     Visitor.Leave_Image
                       (Destination => Annotation.Destination,
                        Title       =>
                           Annotation.Title.Join_Lines (VSS.Strings.LF));

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
               Visitor.Visit_Text (Text.Plain_Text.Slice (Next, Last));

               Next.Set_At (Last);
               Ignore := Next.Forward;
            end;
         end if;
      end Iterate;

      Index : Positive := Text.Annotation.First_Index;
      Next  : VSS.Strings.Character_Iterators.Character_Iterator :=
        Text.Plain_Text.At_First_Character;

   begin
      Iterate
        (Index => Index,
         Next  => Next,
         Limit => Text.Plain_Text.Character_Length);
   end Iterate;

end Markdown.Annotations.Visitors;
