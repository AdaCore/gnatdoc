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
with GNATdoc.Comments.Options;
with GNATdoc.Entities;

package body GNATdoc.Frontend is

   use GNATdoc.Comments.Extractor;
   use GNATdoc.Comments.Options;
   use Libadalang.Analysis;
   use Libadalang.Common;
   use VSS.Strings;

   use type  GNATdoc.Entities.Entity_Information_Access;

   procedure Process_Package_Decl
     (Node      : Package_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Package_Body
     (Node      : Package_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Classic_Subp_Decl
     (Node      : Classic_Subp_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Base_Subp_Body
     (Node      : Base_Subp_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access);
   --  Process subprogram body: Subp_Body, Null_Subp_Decl.

   procedure Process_Simple_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);
   --  Process simple data types: Enum_Type_Def, Mod_Int_Type_Def,
   --  Signed_Int_Type_Def

   procedure Process_Array_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Record_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Private_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Derived_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Interface_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Type_Access_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Subtype_Decl
     (Node      : Subtype_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Object_Decl
     (Node      : Object_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Number_Decl
     (Node      : Number_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Generic_Instantiation
     (Node      : Generic_Instantiation'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access);
   --  Process geenric instantiations: Generic_Package_Instantiation and
   --  Generic_Subp_Instantiation.

   procedure Process_Package_Renaming_Decl
     (Node      : Package_Renaming_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Children
     (Parent    : Ada_Node'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);
   --  Process children nodes, filter out important nodes, and dispatch to
   --  corresponding documentation extraction and entity creation subprograms.

   Extract_Options : GNATdoc.Comments.Options.Extractor_Options :=
     (GNAT, False);

   ----------------------------
   -- Process_Array_Type_Def --
   ----------------------------

   procedure Process_Array_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Array_Types.Insert (Entity);
   end Process_Array_Type_Def;

   ----------------------------
   -- Process_Base_Subp_Body --
   ----------------------------

   procedure Process_Base_Subp_Body
     (Node      : Base_Subp_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
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
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);

      if Global /= null then
         Global.Subprograms.Insert (Entity);
      end if;
   end Process_Base_Subp_Body;

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
               case Node.As_Type_Decl.F_Type_Def.Kind is
                  when Ada_Private_Type_Def =>
                     --  Private_Type_Def nodes are ignored when documentation
                     --  of declarations in private part are generated.

                     if not Options.Generate_Private then
                        Process_Private_Type_Def
                          (Node.As_Type_Decl, Enclosing);
                     end if;

                  when Ada_Record_Type_Def =>
                     Process_Record_Type_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Enum_Type_Def
                     | Ada_Mod_Int_Type_Def
                     | Ada_Signed_Int_Type_Def
                     =>
                     Process_Simple_Type_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Type_Access_Def =>
                     Process_Type_Access_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Derived_Type_Def =>
                     --  Derived types with private part are ignored when
                     --  documentation for declarations in private part are
                     --  generated.

                     if not Options.Generate_Private
                       or else not Node.As_Type_Decl.F_Type_Def
                                     .As_Derived_Type_Def.F_Has_With_Private
                     then
                        Process_Derived_Type_Def
                          (Node.As_Type_Decl, Enclosing);
                     end if;

                  when Ada_Interface_Type_Def =>
                     Process_Interface_Type_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Array_Type_Def =>
                     Process_Array_Type_Def (Node.As_Type_Decl, Enclosing);

                  when others =>
                     Ada.Text_IO.Put_Line
                       (Image (Node) & " => "
                        & Image (Node.As_Type_Decl.F_Type_Def));
               end case;

               return Over;

            when Ada_Subtype_Decl =>
               Process_Subtype_Decl (Node.As_Subtype_Decl, Enclosing);

               return Over;

            when Ada_Incomplete_Type_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Incomplete_Tagged_Type_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Subp_Decl =>
               Process_Classic_Subp_Decl (Node.As_Subp_Decl, Enclosing, null);

               return Over;

            when Ada_Abstract_Subp_Decl =>
               Process_Classic_Subp_Decl
                 (Node.As_Abstract_Subp_Decl, Enclosing, null);

               return Over;

            when Ada_Null_Subp_Decl =>
               Process_Base_Subp_Body
                 (Node.As_Null_Subp_Decl, Enclosing, null);

               return Over;

            when Ada_Subp_Body =>
               Process_Base_Subp_Body (Node.As_Subp_Body, Enclosing, null);

               return Over;

            when Ada_Expr_Function =>
               Process_Base_Subp_Body (Node.As_Expr_Function, Enclosing, null);

               return Over;

            when Ada_Generic_Subp_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Generic_Package_Instantiation =>
               Process_Generic_Instantiation
                 (Node.As_Generic_Package_Instantiation, Enclosing, null);

               return Over;

            when Ada_Generic_Subp_Instantiation =>
               Process_Generic_Instantiation
                 (Node.As_Generic_Subp_Instantiation, Enclosing, null);

               return Over;

            when Ada_Subp_Renaming_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Package_Renaming_Decl =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when Ada_Object_Decl =>
               --  Constant in package specifications may be declared twice:
               --  first time in the public part and second time in the private
               --  part. When documentation is generated for private part of
               --  the package constant declarations that has completion in the
               --  private part are ignored.

               if not Node.As_Object_Decl.F_Has_Constant
                 or not Options.Generate_Private
                 or Node.As_Object_Decl.P_Private_Part_Decl.Is_Null
               then
                  Process_Object_Decl (Node.As_Object_Decl, Enclosing);
               end if;

               return Over;

            when Ada_Number_Decl =>
               Process_Number_Decl (Node.As_Number_Decl, Enclosing);

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
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
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
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);

      if Global /= null then
         Global.Subprograms.Insert (Entity);
      end if;
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
                  GNATdoc.Entities.Global_Entities'Access,
                  GNATdoc.Entities.TOC_Entities'Access);

               return Over;

            when Ada_Subp_Body =>
               --  Process subprogram body when documentation for bodies is
               --  not generated and subprogram doesn't have subprogram
               --  specification unit, to include it in the list of the all
               --  units.

               if Options.Generate_Body
                 or Node.As_Subp_Body.F_Subp_Spec
                      .F_Subp_Name.P_Previous_Part.Is_Null
               then
                  Process_Base_Subp_Body
                    (Node.As_Subp_Body,
                     GNATdoc.Entities.Global_Entities'Access,
                     GNATdoc.Entities.TOC_Entities'Access);
               end if;

               return Over;

            when Ada_Package_Renaming_Decl =>
               Process_Package_Renaming_Decl
                 (Node.As_Package_Renaming_Decl,
                  GNATdoc.Entities.Global_Entities'Access,
                  GNATdoc.Entities.TOC_Entities'Access);

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

   ------------------------------
   -- Process_Derived_Type_Def --
   ------------------------------

   procedure Process_Derived_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      if Node.F_Type_Def.As_Derived_Type_Def.F_Has_With_Private
        or not Node.F_Type_Def.As_Derived_Type_Def.F_Record_Extension.Is_Null
      then
         Enclosing.Tagged_Types.Insert (Entity);

      else
         Enclosing.Simple_Types.Insert (Entity);
      end if;
   end Process_Derived_Type_Def;

   -----------------------------------
   -- Process_Generic_Instantiation --
   -----------------------------------

   procedure Process_Generic_Instantiation
     (Node      : Generic_Instantiation'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
   is
      Name      : constant Defining_Name :=
        (if Node.Kind = Ada_Generic_Package_Instantiation
         then Node.As_Generic_Package_Instantiation.F_Name
         else Node.As_Generic_Subp_Instantiation.F_Subp_Name);
      Signature : constant Virtual_String :=
        (if Node.Kind = Ada_Generic_Package_Instantiation
         then To_Virtual_String (Name.P_Unique_Identifying_Name)
         else To_Virtual_String
                (Name.P_Unique_Identifying_Name & Name.Full_Sloc_Image));
      --  ??? LAL: bug in P_Unique_Identifying_Name for generic subprogram
      --  instantiations

      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature,
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Generic_Instantiations.Insert (Entity);

      if Global /= null then
         Global.Generic_Instantiations.Insert (Entity);
      end if;
   end Process_Generic_Instantiation;

   --------------------------------
   -- Process_Interface_Type_Def --
   --------------------------------

   procedure Process_Interface_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Interface_Types.Insert (Entity);
   end Process_Interface_Type_Def;

   -------------------------
   -- Process_Number_Decl --
   -------------------------

   procedure Process_Number_Decl
     (Node      : Number_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access) is
   begin
      for Name of Node.F_Ids loop
         declare
            Entity : constant not null
              GNATdoc.Entities.Entity_Information_Access :=
                new GNATdoc.Entities.Entity_Information'
                  (Name           =>
                     To_Virtual_String (Name.F_Name.Text),
                   Qualified_Name =>
                     To_Virtual_String (Name.P_Fully_Qualified_Name),
                   Signature      =>
                     To_Virtual_String (Name.P_Unique_Identifying_Name),
                   Documentation  => Extract (Node, Extract_Options),
                   others         => <>);

         begin
            Enclosing.Constants.Insert (Entity);
         end;
      end loop;
   end Process_Number_Decl;

   -------------------------
   -- Process_Object_Decl --
   -------------------------

   procedure Process_Object_Decl
     (Node      : Object_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access) is
   begin
      for Name of Node.F_Ids loop
         declare
            Entity : constant not null
              GNATdoc.Entities.Entity_Information_Access :=
                new GNATdoc.Entities.Entity_Information'
                  (Name           =>
                     To_Virtual_String (Name.F_Name.Text),
                   Qualified_Name =>
                     To_Virtual_String (Name.P_Fully_Qualified_Name),
                   Signature      =>
                     To_Virtual_String (Name.P_Unique_Identifying_Name),
                   Documentation  => Extract (Node, Extract_Options),
                   others         => <>);

         begin
            if Node.F_Has_Constant then
               Enclosing.Constants.Insert (Entity);

            else
               Enclosing.Variables.Insert (Entity);
            end if;
         end;
      end loop;
   end Process_Object_Decl;

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
           Documentation  => <>,
           others         => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      GNATdoc.Entities.TOC_Entities.Packages.Insert (Entity);
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
           Documentation  => <>,
           others         => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      GNATdoc.Entities.TOC_Entities.Packages.Insert (Entity);
      Process_Children (Node.F_Decls, Entity);
   end Process_Package_Body;

   -----------------------------------
   -- Process_Package_Renaming_Decl --
   -----------------------------------

   procedure Process_Package_Renaming_Decl
     (Node      : Package_Renaming_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String (Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Renamings.Insert (Entity);

      if Global /= null then
         Global.Renamings.Insert (Entity);
      end if;
   end Process_Package_Renaming_Decl;

   ------------------------------
   -- Process_Private_Type_Def --
   ------------------------------

   procedure Process_Private_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      if Node.F_Type_Def.As_Private_Type_Def.F_Has_Tagged then
         Enclosing.Tagged_Types.Insert (Entity);

      else
         Enclosing.Simple_Types.Insert (Entity);
      end if;
   end Process_Private_Type_Def;

   -----------------------------
   -- Process_Record_Type_Def --
   -----------------------------

   procedure Process_Record_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Record_Types.Insert (Entity);
   end Process_Record_Type_Def;

   -----------------------------
   -- Process_Simple_Type_Def --
   -----------------------------

   procedure Process_Simple_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Simple_Types.Insert (Entity);
   end Process_Simple_Type_Def;

   --------------------------
   -- Process_Subtype_Decl --
   --------------------------

   procedure Process_Subtype_Decl
     (Node      : Subtype_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Subtypes.Insert (Entity);
   end Process_Subtype_Decl;

   -----------------------------
   -- Process_Type_Access_Def --
   -----------------------------

   procedure Process_Type_Access_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Name           => To_Virtual_String (Node.F_Name.Text),
           Qualified_Name =>
             To_Virtual_String
               (Node.F_Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String
               (Node.F_Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, Extract_Options),
           others         => <>);

   begin
      Enclosing.Access_Types.Insert (Entity);
   end Process_Type_Access_Def;

end GNATdoc.Frontend;
