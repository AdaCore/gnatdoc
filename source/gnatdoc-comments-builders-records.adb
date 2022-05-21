------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2022, AdaCore                        --
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

with Ada.Text_IO; use Ada.Text_IO;

with Libadalang.Common;

package body GNATdoc.Comments.Builders.Records is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -----------
   -- Build --
   -----------

   procedure Build
     (Self            : in out Record_Components_Builder;
      Documentation   : not null GNATdoc.Comments.Structured_Comment_Access;
      Options         : GNATdoc.Comments.Extractor.Extractor_Options;
      Node            : Libadalang.Analysis.Type_Decl'Class;
      Advanced_Groups : out Boolean;
      Last_Section    : out GNATdoc.Comments.Section_Access;
      Minimum_Indent  : out Langkit_Support.Slocs.Column_Number)
   is
      function Process (Node : Ada_Node'Class) return Visit_Status;

      -------------
      -- Process --
      -------------

      function Process (Node : Ada_Node'Class) return Visit_Status is
      begin
         case Node.Kind is
            when Ada_Component_List | Ada_Variant_Part | Ada_Variant =>
               --  Restart group of components at the beginning of the
               --   - Ada_Component_List - to complete group of discriminants
               --   - Ada_Variant_Part - to complete group of components before
               --     the start of variants
               --   - Ada_Variant - to complete group of components before
               --     the start of components of the next alternative

               Self.Restart_Component_Group (Node.Sloc_Range.Start_Line);

               return Into;

            when Ada_Ada_Node_List | Ada_Variant_List =>
               return Into;

            when Ada_Alternatives_List | Ada_Others_Designator =>
               return Into;

            when Ada_Null_Component_Decl | Ada_Identifier | Ada_Dotted_Name
               | Ada_Int_Literal
               =>
               return Over;

            when Ada_Known_Discriminant_Part | Ada_Discriminant_Spec_List =>
               return Into;

            when Ada_Component_Decl =>
               Self.Process_Component_Declaration (Node.As_Component_Decl);

               for Name of Node.As_Component_Decl.F_Ids loop
                  Self.Process_Defining_Name (Member, Name);
               end loop;

               return Over;

            when Ada_Discriminant_Spec =>
               Self.Process_Component_Declaration (Node.As_Discriminant_Spec);

               for Name of Node.As_Discriminant_Spec.F_Ids loop
                  Self.Process_Defining_Name (Member, Name);
               end loop;

               return Over;

            when others =>
               Put_Line (Image (Node));

               raise Program_Error with Ada_Node_Kind_Type'Image (Node.Kind);
         end case;
      end Process;

      Discriminants : constant Discriminant_Part := Node.F_Discriminants;
      Components    : constant Component_List    :=
        Node.F_Type_Def.As_Record_Type_Def.F_Record_Def.F_Components;

   begin
      Self.Initialize (Documentation, Options, Node);

      if not Node.F_Discriminants.Is_Null then
         Node.F_Discriminants.Traverse (Process'Access);
      end if;

      Components.Traverse (Process'Access);

      Advanced_Groups := Self.Advanced_Groups;
      Last_Section    := Self.Last_Section;
      Minimum_Indent  := Self.Minimum_Indent;
   end Build;

end GNATdoc.Comments.Builders.Records;
