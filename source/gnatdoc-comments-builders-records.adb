------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2023, AdaCore                     --
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

with Libadalang.Common;

with GNATdoc.Messages;

package body GNATdoc.Comments.Builders.Records is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -----------
   -- Build --
   -----------

   procedure Build
     (Self           : in out Record_Components_Builder;
      Sections       : not null GNATdoc.Comments.Sections_Access;
      Options        : GNATdoc.Comments.Options.Extractor_Options;
      Node           : Libadalang.Analysis.Type_Decl'Class;
      Last_Section   : out GNATdoc.Comments.Section_Access;
      Minimum_Indent : out Langkit_Support.Slocs.Column_Number)
   is
      function Process (Node : Ada_Node'Class) return Visit_Status;

      -------------
      -- Process --
      -------------

      function Process (Node : Ada_Node'Class) return Visit_Status is
         Done    : Boolean;
         Control : Visit_Status;

      begin
         Self.Process_Discriminants_Node (Node, Done, Control);

         if Done then
            return Control;
         end if;

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

            when Ada_Alternatives_List =>
               return Over;

            when Ada_Identifier =>
               --  Discriminant name in the variant part

               return Over;

            when Ada_Null_Component_Decl =>
               --  null component is not included into documentation

               return Over;

            when Ada_Pragma_Node =>
               return Over;

            when Ada_Component_Decl =>
               Self.Process_Component_Declaration (Node.As_Component_Decl);

               for Name of Node.As_Component_Decl.F_Ids loop
                  Self.Process_Defining_Name (Field, Name);
               end loop;

               return Over;

            when others =>
               GNATdoc.Messages.Raise_Not_Implemented (Image (Node));
         end case;
      end Process;

      Discriminants : constant Discriminant_Part := Node.F_Discriminants;
      Components    : constant Component_List    :=
        (if Node.F_Type_Def.Kind = Ada_Record_Type_Def
         then Node.F_Type_Def.As_Record_Type_Def.F_Record_Def.F_Components
         else Node.F_Type_Def.As_Derived_Type_Def
                .F_Record_Extension.F_Components);

   begin
      Self.Initialize (Sections, Options, Node);

      if not Discriminants.Is_Null then
         Discriminants.Traverse (Process'Access);
      end if;

      Components.Traverse (Process'Access);
      Self.Restart_Component_Group (Node.Sloc_Range.End_Line);

      Self.Fill_Structured_Comment (Node, Options.Pattern);

      Last_Section    := Self.Last_Section;
      Minimum_Indent  := Self.Minimum_Indent;
   end Build;

end GNATdoc.Comments.Builders.Records;
