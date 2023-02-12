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

package body GNATdoc.Comments.Builders.Protecteds is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -----------
   -- Build --
   -----------

   procedure Build
     (Self          : in out Protected_Components_Builder;
      Documentation : not null GNATdoc.Comments.Structured_Comment_Access;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Node          : Libadalang.Analysis.Basic_Decl'Class)
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
            when Ada_Private_Part | Ada_Decl_List =>
               --  Nodes that contains significant nodes inside thier
               --  subtrees.

               return Into;

            when Ada_Pragma_Node =>
               --  Nodes that doesn't contains significant information.

               return Over;

            when Ada_Component_Decl =>
               Self.Process_Component_Declaration (Node.As_Component_Decl);

               for Name of Node.As_Component_Decl.F_Ids loop
                  Self.Process_Defining_Name (Field, Name);
               end loop;

               return Over;

            when Ada_Subp_Decl | Ada_Entry_Decl =>
               Self.Restart_Component_Group (Node.Sloc_Range.Start_Line);

               return Over;

            when others =>
               raise Program_Error with Ada_Node_Kind_Type'Image (Node.Kind);
         end case;
      end Process;

      Discriminants : constant Discriminant_Part :=
        (case Node.Kind is
            when Ada_Protected_Type_Decl =>
              Node.As_Protected_Type_Decl.F_Discriminants,
            when others                  => No_Discriminant_Part);
      Definition    : constant Protected_Def :=
        (case Node.Kind is
            when Ada_Single_Protected_Decl =>
              Node.As_Single_Protected_Decl.F_Definition,
            when Ada_Protected_Type_Decl   =>
              Node.As_Protected_Type_Decl.F_Definition,
            when others                    => No_Protected_Def);

   begin
      Self.Initialize (Documentation, Options, Node);

      --  Process discriminants of the protected type declaration.

      if not Discriminants.Is_Null then
         Discriminants.Traverse (Process'Access);

         --  Detect first line of the next declartion after discriminants part

         declare
            Token : Token_Reference := Discriminants.Token_End;

         begin
            loop
               Token := Next (Token);

               exit when Token = No_Token;

               case Kind (Data (Token)) is
                  when Ada_Whitespace | Ada_Comment =>
                     --  Ignore whitespace separators and comments

                     null;

                  when Ada_Is | Ada_With =>
                     --  Ignore 'is' and 'with' keyword that starts aspects
                     --  specification, interface list of public parts of
                     --  protected specification: they may be left on the
                     --  same line with last discriminant.

                     null;

                  when others =>
                     exit;
               end case;
            end loop;

            if Token /= No_Token then
               Self.Restart_Component_Group
                 (Sloc_Range (Data (Token)).End_Line);
            end if;
         end;
      end if;

      --  Components of the private type can be declared in the private part
      --  only. Public part can contains subprograms/entries only, thus ignore
      --  hole public part.
      --
      --  ??? Should it be controlled by the "generate private" option ???

      if not Definition.F_Private_Part.Is_Null then
         Definition.F_Private_Part.Traverse (Process'Access);
         Self.Restart_Component_Group (Node.Sloc_Range.End_Line);
      end if;

      Self.Fill_Structured_Comment (Node, Options.Pattern);
   end Build;

end GNATdoc.Comments.Builders.Protecteds;
