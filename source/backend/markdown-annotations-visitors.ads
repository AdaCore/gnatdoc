--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package Markdown.Annotations.Visitors
  with Preelaborate
is

   type Annotated_Text_Visitor is limited interface;

   not overriding procedure Visit_Text
     (Self : in out Annotated_Text_Visitor;
      Text : VSS.Strings.Virtual_String) is abstract;

   not overriding procedure Enter_Emphasis
     (Self : in out Annotated_Text_Visitor) is abstract;

   not overriding procedure Leave_Emphasis
     (Self : in out Annotated_Text_Visitor) is abstract;

   not overriding procedure Enter_Strong
     (Self : in out Annotated_Text_Visitor) is abstract;

   not overriding procedure Leave_Strong
     (Self : in out Annotated_Text_Visitor) is abstract;

   not overriding procedure Enter_Code_Span
     (Self : in out Annotated_Text_Visitor) is abstract;

   not overriding procedure Leave_Code_Span
     (Self : in out Annotated_Text_Visitor) is abstract;

   not overriding procedure Enter_Image
     (Self        : in out Annotated_Text_Visitor;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String) is abstract;

   not overriding procedure Leave_Image
     (Self        : in out Annotated_Text_Visitor;
      Destination : VSS.Strings.Virtual_String;
      Title       : VSS.Strings.Virtual_String) is abstract;

   type Annotated_Text_Iterator is tagged limited private;

   procedure Iterate
     (Self    : in out Annotated_Text_Iterator'Class;
      Text    : Markdown.Annotations.Annotated_Text'Class;
      Visitor : in out Annotated_Text_Visitor'Class);

private

   type Annotated_Text_Iterator is tagged limited record
      null;
   end record;

end Markdown.Annotations.Visitors;
