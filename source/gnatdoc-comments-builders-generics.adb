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

package body GNATdoc.Comments.Builders.Generics is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -----------
   -- Build --
   -----------

   procedure Build
     (Self             : in out Generic_Components_Builder;
      Sections         : not null GNATdoc.Comments.Sections_Access;
      Options          : GNATdoc.Comments.Options.Extractor_Options;
      Node             : Libadalang.Analysis.Generic_Decl'Class;
      Formal_Part_Node : Libadalang.Analysis.Generic_Formal_Part'Class;
      Basic_Decl_Node  : Libadalang.Analysis.Basic_Decl'Class) is
   begin
      Self.Initialize (Sections, Options, Formal_Part_Node);

      Self.Advanced_Groups := False;
      --  Advanced groups is not supported for generic formal parameters.

      for Item of Formal_Part_Node.F_Decls loop
         Self.Process_Component_Declaration (Item);

         case Item.Kind is
            when Ada_Generic_Formal_Type_Decl =>
               declare
                  Decl : constant Basic_Decl :=
                    Item.As_Generic_Formal_Type_Decl.F_Decl;
                  Name : constant Defining_Name :=
                    (case Decl.Kind is
                        when Ada_Incomplete_Formal_Type_Decl =>
                          Decl.As_Incomplete_Formal_Type_Decl.F_Name,
                        when Ada_Formal_Type_Decl =>
                          Decl.As_Formal_Type_Decl.F_Name,
                        when others => raise Program_Error);

               begin
                  Self.Process_Defining_Name (Formal, Name);
               end;

            when Ada_Generic_Formal_Subp_Decl =>
               Self.Process_Defining_Name
                 (Formal,
                  Item.As_Generic_Formal_Subp_Decl.F_Decl
                    .As_Concrete_Formal_Subp_Decl.F_Subp_Spec.F_Subp_Name);

            when Ada_Generic_Formal_Obj_Decl =>
               for Id of
                 Item.As_Generic_Formal_Obj_Decl.F_Decl.As_Object_Decl.F_Ids
               loop
                  Self.Process_Defining_Name (Formal, Id);
               end loop;

            when Ada_Generic_Formal_Package =>
               Self.Process_Defining_Name
                 (Formal,
                  Item.As_Generic_Formal_Package.F_Decl
                    .As_Generic_Package_Instantiation.F_Name);

            when Ada_Pragma_Node =>
               --  Ignore all pragmas.

               null;

            when others =>
               GNATdoc.Messages.Raise_Not_Implemented (Image (Item));
         end case;
      end loop;

      Self.Restart_Component_Group (Basic_Decl_Node.Sloc_Range.Start_Line);

      Self.Fill_Structured_Comment (Node, Options.Pattern);
   end Build;

end GNATdoc.Comments.Builders.Generics;
