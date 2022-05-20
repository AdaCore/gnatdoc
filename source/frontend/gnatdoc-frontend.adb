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

with Ada.Text_IO;

with Libadalang.Common;

with VSS.Strings.Conversions;

with GNATdoc.Comments.Extractor;
with GNATdoc.Entities;

package body GNATdoc.Frontend is

   use GNATdoc.Comments.Extractor;
   use Libadalang.Analysis;
   use Libadalang.Common;
   use VSS.Strings;

   procedure Process_Package_Decl
     (Node      : Package_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Package_Body
     (Node      : Package_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Classic_Subp_Decl
     (Node      : Classic_Subp_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Subp_Body
     (Node      : Subp_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Children
     (Parent    : Ada_Node'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);
   --  Process children nodes, filter out important nodes, and dispatch to
   --  corresponding documentation extraction and entity creation subprograms.

   ----------------------
   -- Process_Children --
   ----------------------

   procedure Process_Children
     (Parent    : Ada_Node'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is

      function Process_Node (Node : Ada_Node'Class) return Visit_Status;

      ------------------
      -- Process_Node --
      ------------------

      function Process_Node (Node : Ada_Node'Class) return Visit_Status is
      begin
         case Node.Kind is
            when Ada_Type_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Subtype_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Incomplete_Type_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Incomplete_Tagged_Type_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Subp_Decl =>
               Process_Classic_Subp_Decl (Node.As_Subp_Decl, Enclosing);

               return Over;

            when Ada_Abstract_Subp_Decl =>
               Process_Classic_Subp_Decl
                 (Node.As_Abstract_Subp_Decl, Enclosing);

               return Over;

            when Ada_Null_Subp_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Subp_Body =>
               Process_Subp_Body (Node.As_Subp_Body, Enclosing);

               return Over;

            when Ada_Expr_Function =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Generic_Subp_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Generic_Package_Instantiation =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Generic_Subp_Instantiation =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Subp_Renaming_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Package_Renaming_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Object_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Number_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Exception_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Package_Decl =>
               Process_Package_Decl (Node.As_Package_Decl, Enclosing);

               return Over;

            when Ada_Package_Body =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Package_Body_Stub =>
               Process_Package_Body
                 (Node.As_Package_Body_Stub.P_Next_Part_For_Decl
                    .As_Package_Body,
                  Enclosing);

               return Over;

            when Ada_Generic_Package_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Ada_Node_List
               | Ada_Public_Part | Ada_Private_Part
               | Ada_Declarative_Part
            =>
               --  These nodes doesn't contribute to documentation but enclose
               --  other meaningful nodes.

               return Into;

            when Ada_Use_Type_Clause | Ada_Use_Package_Clause
                   | Ada_Pragma_Node
                   | Ada_Record_Rep_Clause | Ada_Enum_Rep_Clause
                   | Ada_Attribute_Def_Clause
            =>
               --  These nodes doesn't contribute to documentation and
               --  are ignored.

               return Over;

            when others =>
               Ada.Text_IO.Put_Line (Image (Node) & " <<<<<");

               return Into;
         end case;
      end Process_Node;

   begin
      if not Parent.Is_Null then
         Parent.Traverse (Process_Node'Access);
      end if;
   end Process_Children;

   -------------------------------
   -- Process_Classic_Subp_Decl --
   -------------------------------

   procedure Process_Classic_Subp_Decl
     (Node      : Classic_Subp_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           =>
             To_Virtual_String (Node.F_Subp_Spec.F_Subp_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Subp_Spec.F_Subp_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Subp_Spec.F_Subp_Name.P_Unique_Identifying_Name) & "$",
           Documentation  => Extract (Node, (others => <>)),
           Packages       => <>,
           Subprograms    => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);
   end Process_Classic_Subp_Decl;

   ------------------------------
   -- Process_Compilation_Unit --
   ------------------------------

   procedure Process_Compilation_Unit
     (Unit : Libadalang.Analysis.Compilation_Unit'Class)
   is
      function Process_Node (Node : Ada_Node'Class) return Visit_Status;

      ------------------
      -- Process_Node --
      ------------------

      function Process_Node (Node : Ada_Node'Class) return Visit_Status is
      begin
         case Node.Kind is
            when Ada_Library_Item | Ada_Private_Absent | Ada_Private_Present =>
               return Into;

            when Ada_Package_Decl =>
               Process_Package_Decl
                 (Node.As_Package_Decl,
                  GNATdoc.Entities.Global_Entities'Access);

               return Over;

            when Ada_Package_Body =>
               if Options.Generate_Body then
                  Process_Package_Body
                    (Node.As_Package_Body,
                     GNATdoc.Entities.Global_Entities'Access);
               end if;

               return Over;

            when Ada_Subp_Decl =>
               Process_Classic_Subp_Decl
                 (Node.As_Subp_Decl,
                  GNATdoc.Entities.Global_Entities'Access);

               return Over;

            when Ada_Subp_Body =>
               --  ??? Check whether Options.Generate_Body is disabled and
               --  there is spec available. Or define other convention to
               --  process "subprogram body as compilation unit".

               Process_Subp_Body
                 (Node.As_Subp_Body,
                  GNATdoc.Entities.Global_Entities'Access);

               return Over;

            when Ada_Package_Renaming_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Subunit =>
               --  Subunits are processed as part of processing of enclosing
               --  unit.

               return Over;

            when others =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Into;
         end case;
      end Process_Node;

   begin
      Unit.F_Body.Traverse (Process_Node'Access);
   end Process_Compilation_Unit;

   --------------------------
   -- Process_Package_Decl --
   --------------------------

   procedure Process_Package_Decl
     (Node      : Package_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           =>
             To_Virtual_String (Node.F_Package_Name.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Package_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Package_Name.P_Unique_Identifying_Name) & "$",
           Documentation  => null,
           Packages       => <>,
           Subprograms    => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      Process_Children (Node.F_Public_Part, Entity);

      if Options.Generate_Private then
         Process_Children (Node.F_Private_Part, Entity);
      end if;
   end Process_Package_Decl;

   --------------------------
   -- Process_Package_Body --
   --------------------------

   procedure Process_Package_Body
     (Node      : Package_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           =>
             To_Virtual_String (Node.F_Package_Name.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Package_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Package_Name.P_Unique_Identifying_Name) & "$$",
           Documentation  => null,
           Packages       => <>,
           Subprograms    => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      Process_Children (Node.F_Decls, Entity);
   end Process_Package_Body;

   -----------------------
   -- Process_Subp_Body --
   -----------------------

   procedure Process_Subp_Body
     (Node      : Subp_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           =>
             To_Virtual_String (Node.F_Subp_Spec.F_Subp_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Subp_Spec.F_Subp_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Subp_Spec.F_Subp_Name.P_Unique_Identifying_Name) & "$$",
           Documentation  => null,
           Packages       => <>,
           Subprograms    => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);
   end Process_Subp_Body;

end GNATdoc.Frontend;
