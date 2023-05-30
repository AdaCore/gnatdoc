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

with Ada.Text_IO;

with Langkit_Support.Slocs;
with Libadalang.Common;

with VSS.Strings.Conversions;

with GNATdoc.Comments.Extractor;
with GNATdoc.Comments.Undocumented_Checker;
with GNATdoc.Configuration;
with GNATdoc.Entities;
with GNATdoc.Messages;
with GNATdoc.Options;

package body GNATdoc.Frontend is

   use GNATdoc.Comments.Extractor;
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
   --  Process simple data types: Enum_Type_Def, Decimal_Fixed_Point_Def,
   --  Ada_Floating_Point_Def, Mod_Int_Type_Def, Ada_Ordinary_Fixed_Point_Def,
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

   procedure Process_Access_Type_Def
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

   procedure Process_Exception_Decl
     (Node      : Exception_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);
   --  Process exception declaration.

   procedure Process_Generic_Package_Decl
     (Node      : Generic_Package_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Generic_Subp_Decl
     (Node      : Generic_Subp_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access);

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

   procedure Process_Task_Decl
     (Node      : Basic_Decl'Class;
      Decl      : Task_Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
     with Pre => Node.Kind in Ada_Single_Task_Decl | Ada_Task_Type_Decl;

   procedure Process_Protected_Decl
     (Node       : Basic_Decl'Class;
      Name       : Defining_Name'Class;
      Definition : Protected_Def'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access)
     with
       Pre => Node.Kind in Ada_Single_Protected_Decl | Ada_Protected_Type_Decl;

   procedure Process_Protected_Body
     (Node      : Protected_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Entry_Decl
     (Node      : Entry_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Entry_Body
     (Node      : Entry_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Children
     (Parent    : Ada_Node'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);
   --  Process children nodes, filter out important nodes, and dispatch to
   --  corresponding documentation extraction and entity creation subprograms.

   procedure Construct_Generic_Formals
     (Entity  : not null GNATdoc.Entities.Entity_Information_Access;
      Name    : Libadalang.Analysis.Defining_Name'Class;
      Formals : Generic_Formal_Part);
   --  Constructs entities for formal parameters of the generic from the
   --  structured comment of the generic.

   function Location
     (Name : Ada_Node'Class) return GNATdoc.Entities.Entity_Location;
   --  Return location of the given node.

   function Signature (Name : Defining_Name'Class) return Virtual_String;
   --  Computes unique signature of the given entity.

   procedure Check_Undocumented
     (Entity : not null GNATdoc.Entities.Entity_Information_Access);
   --  Check whether entiry and all components of the entity are documented.
   --  Generate warnings when they are enabled.

   function RST_Profile
     (Node : Libadalang.Analysis.Subp_Spec'Class)
      return VSS.Strings.Virtual_String;

   ------------------------
   -- Check_Undocumented --
   ------------------------

   procedure Check_Undocumented
     (Entity : not null GNATdoc.Entities.Entity_Information_Access) is
   begin
      if GNATdoc.Configuration.Provider.Warnings_Enabled then
         GNATdoc.Comments.Undocumented_Checker.Check_Undocumented
           (Entity.Location, Entity.Name, Entity.Documentation);
      end if;
   end Check_Undocumented;

   -------------------------------
   -- Construct_Generic_Formals --
   -------------------------------

   procedure Construct_Generic_Formals
     (Entity  : not null GNATdoc.Entities.Entity_Information_Access;
      Name    : Libadalang.Analysis.Defining_Name'Class;
      Formals : Generic_Formal_Part)
   is
      procedure Create_Formal
        (Enclosing      : not null GNATdoc.Entities.Entity_Information_Access;
         Enclosing_Name : Libadalang.Analysis.Defining_Name'Class;
         Name           : Libadalang.Analysis.Defining_Name'Class);
      --  Extract documentation for formal with given name.

      -------------------
      -- Create_Formal --
      -------------------

      procedure Create_Formal
        (Enclosing      : not null GNATdoc.Entities.Entity_Information_Access;
         Enclosing_Name : Libadalang.Analysis.Defining_Name'Class;
         Name           : Libadalang.Analysis.Defining_Name'Class)
      is
         Entity :
           constant not null GNATdoc.Entities.Entity_Information_Access :=
             new GNATdoc.Entities.Entity_Information'
               (Location       => Location (Name),
                Name           => To_Virtual_String (Name.F_Name.Text),
                Qualified_Name =>
                  To_Virtual_String (Name.P_Fully_Qualified_Name),
                Signature      => Signature (Name),
                Enclosing      => Signature (Enclosing_Name),
                Is_Private     => False,
                Documentation  =>
                  GNATdoc.Comments.Extractor.Extract_Formal_Section
                    (Enclosing.Documentation, Name),
                others         => <>);

      begin
         Enclosing.Formals.Insert (Entity);
      end Create_Formal;

   begin
      for Item of Formals.F_Decls loop
         case Item.Kind is
            when Ada_Generic_Formal_Type_Decl =>
               declare
                  Decl        : constant Basic_Decl :=
                    Item.As_Generic_Formal_Type_Decl.F_Decl;
                  Formal_Name : constant Defining_Name :=
                    (case Decl.Kind is
                        when Ada_Incomplete_Formal_Type_Decl =>
                          Decl.As_Incomplete_Formal_Type_Decl.F_Name,
                        when Ada_Formal_Type_Decl =>
                          Decl.As_Formal_Type_Decl.F_Name,
                        when others => raise Program_Error);

               begin
                  Create_Formal (Entity, Name, Formal_Name);
               end;

            when Ada_Generic_Formal_Subp_Decl =>
               Create_Formal
                 (Entity,
                  Name,
                  Item.As_Generic_Formal_Subp_Decl.F_Decl
                    .As_Concrete_Formal_Subp_Decl.F_Subp_Spec.F_Subp_Name);

            when Ada_Generic_Formal_Obj_Decl =>
               for Id of
                 Item.As_Generic_Formal_Obj_Decl.F_Decl.As_Object_Decl.F_Ids
               loop
                  Create_Formal (Entity, Name, Id);
               end loop;

            when Ada_Generic_Formal_Package =>
               Create_Formal
                 (Entity,
                  Name,
                  Item.As_Generic_Formal_Package.F_Decl
                    .As_Generic_Package_Instantiation.F_Name);

            when others =>
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error, Image (Item));
         end case;
      end loop;
   end Construct_Generic_Formals;

   --------------
   -- Location --
   --------------

   function Location
     (Name : Ada_Node'Class) return GNATdoc.Entities.Entity_Location
   is
      Aux : constant Langkit_Support.Slocs.Source_Location_Range :=
        Name.Sloc_Range;

   begin
      return
        (File   =>
           VSS.Strings.Conversions.To_Virtual_String (Name.Unit.Get_Filename),
         Line   => VSS.Strings.Line_Count (Aux.Start_Line),
         Column => VSS.Strings.Character_Count (Aux.Start_Column));
   end Location;

   -----------------------------
   -- Process_Access_Type_Def --
   -----------------------------

   procedure Process_Access_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Access_Types.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Access_Type_Def;

   ----------------------------
   -- Process_Array_Type_Def --
   ----------------------------

   procedure Process_Array_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Array_Types.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Array_Type_Def;

   ----------------------------
   -- Process_Base_Subp_Body --
   ----------------------------

   procedure Process_Base_Subp_Body
     (Node      : Base_Subp_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Subp_Spec.F_Subp_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Kind           =>
             (case Node.F_Subp_Spec.F_Subp_Kind is
                 when Ada_Subp_Kind_Function  =>
                   GNATdoc.Entities.Ada_Function,
                 when Ada_Subp_Kind_Procedure =>
                   GNATdoc.Entities.Ada_Procedure),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           RST_Profile    => RST_Profile (Node.F_Subp_Spec),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Subprograms.Insert (Entity);
      end if;

      Check_Undocumented (Entity);
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

                     if not GNATdoc.Options.Frontend_Options.Generate_Private
                     then
                        Process_Private_Type_Def
                          (Node.As_Type_Decl, Enclosing);
                     end if;

                  when Ada_Record_Type_Def =>
                     Process_Record_Type_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Enum_Type_Def
                     | Ada_Decimal_Fixed_Point_Def
                     | Ada_Floating_Point_Def
                     | Ada_Mod_Int_Type_Def
                     | Ada_Ordinary_Fixed_Point_Def
                     | Ada_Signed_Int_Type_Def
                     =>
                     Process_Simple_Type_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Type_Access_Def | Ada_Access_To_Subp_Def =>
                     Process_Access_Type_Def (Node.As_Type_Decl, Enclosing);

                  when Ada_Derived_Type_Def =>
                     --  Derived types with private part are ignored when
                     --  documentation for declarations in private part are
                     --  generated.

                     if not GNATdoc.Options.Frontend_Options.Generate_Private
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
               Process_Generic_Subp_Decl
                 (Node.As_Generic_Subp_Decl, Enclosing, null);

               return Over;

            when Ada_Generic_Package_Decl =>
               Process_Generic_Package_Decl
                 (Node.As_Generic_Package_Decl, Enclosing);

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
               Process_Base_Subp_Body
                 (Node.As_Subp_Renaming_Decl, Enclosing, null);

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
                 or not GNATdoc.Options.Frontend_Options.Generate_Private
                 or Node.As_Object_Decl.P_Private_Part_Decl.Is_Null
               then
                  Process_Object_Decl (Node.As_Object_Decl, Enclosing);
               end if;

               return Over;

            when Ada_Number_Decl =>
               Process_Number_Decl (Node.As_Number_Decl, Enclosing);

               return Over;

            when Ada_Exception_Decl =>
               Process_Exception_Decl (Node.As_Exception_Decl, Enclosing);

               return Over;

            when Ada_Package_Decl =>
               Process_Package_Decl (Node.As_Package_Decl, Enclosing);

               return Over;

            when Ada_Package_Body =>
               Process_Package_Body (Node.As_Package_Body, Enclosing);

               return Over;

            when Ada_Package_Body_Stub =>
               Process_Package_Body
                 (Node.As_Package_Body_Stub.P_Next_Part_For_Decl
                    .As_Package_Body,
                  Enclosing);

               return Over;

            when Ada_Single_Task_Decl =>
               Process_Task_Decl
                 (Node.As_Basic_Decl,
                  Node.As_Single_Task_Decl.F_Task_Type,
                  Enclosing);

               return Over;

            when Ada_Task_Type_Decl =>
               Process_Task_Decl
                 (Node.As_Basic_Decl,
                  Node.As_Task_Type_Decl,
                  Enclosing);

               return Over;

            when Ada_Single_Protected_Decl =>
               Process_Protected_Decl
                 (Node.As_Single_Protected_Decl,
                  Node.As_Single_Protected_Decl.F_Name,
                  Node.As_Single_Protected_Decl.F_Definition,
                  Enclosing);

               return Over;

            when Ada_Protected_Type_Decl =>
               Process_Protected_Decl
                 (Node.As_Protected_Type_Decl,
                  Node.As_Protected_Type_Decl.F_Name,
                  Node.As_Protected_Type_Decl.F_Definition,
                  Enclosing);

               return Over;

            when Ada_Entry_Decl =>
               Process_Entry_Decl (Node.As_Entry_Decl, Enclosing);

               return Over;

            when Ada_Entry_Body =>
               Process_Entry_Body (Node.As_Entry_Body, Enclosing);

               return Over;

            when Ada_Protected_Body =>
               Process_Protected_Body (Node.As_Protected_Body, Enclosing);

               return Over;

            when Ada_Ada_Node_List
               | Ada_Public_Part | Ada_Private_Part
               | Ada_Declarative_Part
               | Ada_Decl_List
            =>
               --  These nodes doesn't contribute to documentation but enclose
               --  other meaningful nodes.

               return Into;

            when Ada_Use_Type_Clause | Ada_Use_Package_Clause
                   | Ada_Pragma_Node
                   | Ada_Record_Rep_Clause | Ada_Enum_Rep_Clause
                   | Ada_Attribute_Def_Clause
                   | Ada_Task_Body
            =>
               --  These nodes doesn't contribute to documentation and
               --  are ignored.

               return Over;

            when Ada_Component_Decl =>
               --  Component declaration inside private part of the protected
               --  object/type declaration is ignored here.

               return Over;

            when others =>
               Ada.Text_IO.Put_Line (Image (Node) & " <<<<<");

               return Into;
         end case;

      exception
         when E : others =>

            GNATdoc.Messages.Report_Internal_Error (Location (Node), E);

            return Over;
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
      Name   : constant Defining_Name := Node.F_Subp_Spec.F_Subp_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Kind           =>
             (case Node.F_Subp_Spec.F_Subp_Kind is
                 when Ada_Subp_Kind_Function  =>
                   GNATdoc.Entities.Ada_Function,
                 when Ada_Subp_Kind_Procedure =>
                   GNATdoc.Entities.Ada_Procedure),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           RST_Profile    => RST_Profile (Node.F_Subp_Spec),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Subprograms.Insert (Entity);
      end if;

      Check_Undocumented (Entity);
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
                 (Node.As_Package_Decl, GNATdoc.Entities.Globals'Access);

               return Over;

            when Ada_Package_Body =>
               if GNATdoc.Options.Frontend_Options.Generate_Body then
                  Process_Package_Body
                    (Node.As_Package_Body, GNATdoc.Entities.Globals'Access);
               end if;

               return Over;

            when Ada_Subp_Decl =>
               Process_Classic_Subp_Decl
                 (Node.As_Subp_Decl,
                  GNATdoc.Entities.Globals'Access,
                  GNATdoc.Entities.Globals'Access);

               return Over;

            when Ada_Subp_Body =>
               --  Process subprogram body when documentation for bodies is
               --  not generated and subprogram doesn't have subprogram
               --  specification unit, to include it in the list of the all
               --  units.

               if GNATdoc.Options.Frontend_Options.Generate_Body
                 or Node.As_Subp_Body.F_Subp_Spec
                      .F_Subp_Name.P_Previous_Part.Is_Null
               then
                  Process_Base_Subp_Body
                    (Node.As_Subp_Body,
                     GNATdoc.Entities.Globals'Access,
                     GNATdoc.Entities.Globals'Access);
               end if;

               return Over;

            when Ada_Package_Renaming_Decl =>
               Process_Package_Renaming_Decl
                 (Node.As_Package_Renaming_Decl,
                  GNATdoc.Entities.Globals'Access,
                  GNATdoc.Entities.Globals'Access);

               return Over;

            when Ada_Subunit =>
               --  Subunits are processed as part of processing of enclosing
               --  unit.

               return Over;

            when Ada_Generic_Subp_Decl =>
               Process_Generic_Subp_Decl
                 (Node.As_Generic_Subp_Decl,
                  GNATdoc.Entities.Globals'Access,
                  GNATdoc.Entities.Globals'Access);

               return Over;

            when Ada_Generic_Package_Decl =>
               Process_Generic_Package_Decl
                 (Node.As_Generic_Package_Decl,
                  GNATdoc.Entities.Globals'Access);

               return Over;

            when Ada_Generic_Package_Instantiation =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Over;

            when others =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Into;
         end case;

      exception
         when E : others =>
            GNATdoc.Messages.Report_Internal_Error (Location (Node), E);

            return Over;
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
      Name   : constant Defining_Name := Node.F_Name;
      Def    : constant Derived_Type_Def :=
        Node.F_Type_Def.As_Derived_Type_Def;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Kind           => GNATdoc.Entities.Ada_Tagged_Type,
           Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      if Def.F_Has_With_Private or not Def.F_Record_Extension.Is_Null then
         Enclosing.Tagged_Types.Insert (Entity);
         GNATdoc.Entities.Globals.Tagged_Types.Insert (Entity);
         GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

         declare
            Parent_Decl : constant Type_Decl :=
              Def.F_Subtype_Indication.F_Name.P_Referenced_Decl.As_Type_Decl;
            Parent_Name : constant Defining_Name :=
              Def.F_Subtype_Indication.F_Name.P_Referenced_Defining_Name;
            Parent_Def  : Type_Def;

         begin
            case Parent_Decl.Kind is
               when Ada_Formal_Type_Decl =>
                  null;

               when Ada_Concrete_Type_Decl =>
                  Parent_Def := Parent_Decl.As_Concrete_Type_Decl.F_Type_Def;

                  case Parent_Def.Kind is
                     when Ada_Interface_Type_Def =>
                        Entity.Progenitor_Types.Insert
                          ((VSS.Strings.To_Virtual_String
                             (Parent_Name.P_Fully_Qualified_Name),
                           Signature (Parent_Name)));

                     when Ada_Derived_Type_Def
                        | Ada_Private_Type_Def
                        | Ada_Record_Type_Def
                     =>
                        Entity.Parent_Type :=
                          (VSS.Strings.To_Virtual_String
                             (Parent_Name.P_Fully_Qualified_Name),
                           Signature (Parent_Name));

                     when others =>
                        raise Program_Error;
                  end case;

               when others =>
                  raise Program_Error;
            end case;
         end;

         for Item of Def.F_Interfaces loop
            Entity.Progenitor_Types.Insert
              ((VSS.Strings.To_Virtual_String
               (Item.P_Referenced_Defining_Name.P_Fully_Qualified_Name),
               Signature (Item.P_Referenced_Defining_Name)));
         end loop;

      else
         Enclosing.Simple_Types.Insert (Entity);
      end if;

      Check_Undocumented (Entity);
   end Process_Derived_Type_Def;

   ------------------------
   -- Process_Entry_Body --
   ------------------------

   procedure Process_Entry_Body
     (Node      : Entry_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Entry_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Entries.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Entry_Body;

   ------------------------
   -- Process_Entry_Decl --
   ------------------------

   procedure Process_Entry_Decl
     (Node      : Entry_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Spec.F_Entry_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Entries.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Entry_Decl;

   ----------------------------
   -- Process_Exception_Decl --
   ----------------------------

   procedure Process_Exception_Decl
     (Node      : Exception_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access) is
   begin
      for Name of Node.F_Ids loop
         declare
            Entity : constant not null
              GNATdoc.Entities.Entity_Information_Access :=
                new GNATdoc.Entities.Entity_Information'
                  (Location       => Location (Name),
                   Name           => To_Virtual_String (Name.Text),
                   Qualified_Name =>
                     To_Virtual_String (Name.P_Fully_Qualified_Name),
                   Signature      => Signature (Name),
                   Documentation  =>
                     Extract (Node, GNATdoc.Options.Extractor_Options),
                   others         => <>);

         begin
            Enclosing.Exceptions.Insert (Entity);
            Check_Undocumented (Entity);
         end;
      end loop;
   end Process_Exception_Decl;

   -----------------------------------
   -- Process_Generic_Instantiation --
   -----------------------------------

   procedure Process_Generic_Instantiation
     (Node      : Generic_Instantiation'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name :=
        (if Node.Kind = Ada_Generic_Package_Instantiation
         then Node.As_Generic_Package_Instantiation.F_Name
         else Node.As_Generic_Subp_Instantiation.F_Subp_Name);
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Generic_Instantiations.Insert (Entity);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Generic_Instantiations.Insert (Entity);
      end if;

      Check_Undocumented (Entity);
   end Process_Generic_Instantiation;

   -------------------------------
   -- Process_Generic_Subp_Decl --
   -------------------------------

   procedure Process_Generic_Subp_Decl
     (Node      : Generic_Subp_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Global    : GNATdoc.Entities.Entity_Information_Access)
   is
      Decl   : constant Generic_Subp_Internal := Node.F_Subp_Decl;
      Spec   : constant Subp_Spec := Decl.F_Subp_Spec;
      Name   : constant Defining_Name := Spec.F_Subp_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Kind           =>
             (case Spec.F_Subp_Kind is
                 when Ada_Subp_Kind_Function  =>
                   GNATdoc.Entities.Ada_Function,
                 when Ada_Subp_Kind_Procedure =>
                   GNATdoc.Entities.Ada_Procedure),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           RST_Profile    => RST_Profile (Spec),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Subprograms.Insert (Entity);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Subprograms.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Construct_Generic_Formals (Entity, Name, Node.F_Formal_Part);
   end Process_Generic_Subp_Decl;

   ----------------------------------
   -- Process_Generic_Package_Decl --
   ----------------------------------

   procedure Process_Generic_Package_Decl
     (Node      : Generic_Package_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Package_Decl.F_Package_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.F_Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Enclosing      =>
             Signature (Node.P_Parent_Basic_Decl.P_Defining_Name),
           Is_Private     =>
             (Node.Parent.Kind = Ada_Library_Item
                and then Node.Parent.As_Library_Item.F_Has_Private),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Package_Decl.F_Public_Part, Entity);

      if GNATdoc.Options.Frontend_Options.Generate_Private then
         Process_Children (Node.F_Package_Decl.F_Private_Part, Entity);
      end if;

      Construct_Generic_Formals (Entity, Name, Node.F_Formal_Part);
   end Process_Generic_Package_Decl;

   --------------------------------
   -- Process_Interface_Type_Def --
   --------------------------------

   procedure Process_Interface_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Def    : constant Interface_Type_Def :=
        Node.F_Type_Def.As_Interface_Type_Def;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Kind           => GNATdoc.Entities.Ada_Interface_Type,
           Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Interface_Types.Insert (Entity);
      GNATdoc.Entities.Globals.Interface_Types.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      for Item of Def.F_Interfaces loop
         Entity.Progenitor_Types.Insert
           ((VSS.Strings.To_Virtual_String
            (Item.P_Referenced_Defining_Name.P_Fully_Qualified_Name),
            Signature (Item.P_Referenced_Defining_Name)));
      end loop;

      Check_Undocumented (Entity);
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
                  (Location       => Location (Name),
                   Name           => To_Virtual_String (Name.Text),
                   Qualified_Name =>
                     To_Virtual_String (Name.P_Fully_Qualified_Name),
                   Signature      => Signature (Name),
                   Documentation  =>
                     Extract (Node, GNATdoc.Options.Extractor_Options),
                   others         => <>);

         begin
            Enclosing.Constants.Insert (Entity);
            Check_Undocumented (Entity);
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
                  (Location       => Location (Name),
                   Name           => To_Virtual_String (Name.Text),
                   Qualified_Name =>
                     To_Virtual_String (Name.P_Fully_Qualified_Name),
                   Signature      => Signature (Name),
                   Documentation  =>
                     Extract (Node, GNATdoc.Options.Extractor_Options),
                   others         => <>);

         begin
            if Node.F_Has_Constant then
               Enclosing.Constants.Insert (Entity);

            else
               Enclosing.Variables.Insert (Entity);
            end if;

            Check_Undocumented (Entity);
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
      Name   : constant Defining_Name := Node.F_Package_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.F_Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Enclosing      =>
             Signature (Node.P_Parent_Basic_Decl.P_Defining_Name),
           Is_Private     =>
             (Node.Parent.Kind = Ada_Library_Item
                and then Node.Parent.As_Library_Item.F_Has_Private),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Public_Part, Entity);

      if GNATdoc.Options.Frontend_Options.Generate_Private then
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
      Name      : constant Defining_Name := Node.F_Package_Name;
      Canonical : constant Basic_Decl := Node.P_Canonical_Part;
      Entity    : constant not null
        GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.F_Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Enclosing      =>
             Signature
               ((case Canonical.Kind is
                   when Ada_Package_Decl             =>
                     Canonical.As_Package_Decl.F_Package_Name,
                   when Ada_Generic_Package_Internal =>
                     Canonical.As_Generic_Package_Internal.F_Package_Name,
                   when others                       => raise Program_Error)),
           Documentation  => <>,
           others         => <>);

   begin
      Enclosing.Packages.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

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
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      =>
             To_Virtual_String (Name.P_Unique_Identifying_Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Package_Renamings.Insert (Entity);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Package_Renamings.Insert (Entity);
      end if;

      Check_Undocumented (Entity);
   end Process_Package_Renaming_Decl;

   ------------------------------
   -- Process_Private_Type_Def --
   ------------------------------

   procedure Process_Private_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      if Node.F_Type_Def.As_Private_Type_Def.F_Has_Tagged then
         Enclosing.Tagged_Types.Insert (Entity);

      else
         Enclosing.Simple_Types.Insert (Entity);
      end if;

      Check_Undocumented (Entity);
   end Process_Private_Type_Def;

   ----------------------------
   -- Process_Protected_Body --
   ----------------------------

   procedure Process_Protected_Body
     (Node      : Protected_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null
        GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.F_Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Enclosing      =>
             Signature (Node.P_Parent_Basic_Decl.P_Defining_Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Protected_Types.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Decls, Entity);
   end Process_Protected_Body;

   ----------------------------
   -- Process_Protected_Decl --
   ----------------------------

   procedure Process_Protected_Decl
     (Node       : Basic_Decl'Class;
      Name       : Defining_Name'Class;
      Definition : Protected_Def'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.F_Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Enclosing      =>
             Signature (Node.P_Parent_Basic_Decl.P_Defining_Name),
           Is_Private     =>
             (Node.Parent.Kind = Ada_Library_Item
                and then Node.Parent.As_Library_Item.F_Has_Private),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Protected_Types.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Protected_Types.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Definition.F_Public_Part, Entity);

      if GNATdoc.Options.Frontend_Options.Generate_Private then
         Process_Children (Definition.F_Private_Part, Entity);
      end if;
   end Process_Protected_Decl;

   -----------------------------
   -- Process_Record_Type_Def --
   -----------------------------

   procedure Process_Record_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Record_Types.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Record_Type_Def;

   -----------------------------
   -- Process_Simple_Type_Def --
   -----------------------------

   procedure Process_Simple_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Simple_Types.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Simple_Type_Def;

   --------------------------
   -- Process_Subtype_Decl --
   --------------------------

   procedure Process_Subtype_Decl
     (Node      : Subtype_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Subtypes.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Subtype_Decl;

   -----------------------
   -- Process_Task_Decl --
   -----------------------

   procedure Process_Task_Decl
     (Node      : Basic_Decl'Class;
      Decl      : Task_Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Decl.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        new GNATdoc.Entities.Entity_Information'
          (Location       => Location (Name),
           Name           => To_Virtual_String (Name.F_Name.Text),
           Qualified_Name => To_Virtual_String (Name.P_Fully_Qualified_Name),
           Signature      => Signature (Name),
           Enclosing      =>
             Signature (Node.P_Parent_Basic_Decl.P_Defining_Name),
           Is_Private     =>
             (Node.Parent.Kind = Ada_Library_Item
                and then Node.Parent.As_Library_Item.F_Has_Private),
           Documentation  => Extract (Node, GNATdoc.Options.Extractor_Options),
           others         => <>);

   begin
      Enclosing.Task_Types.Insert (Entity);
      GNATdoc.Entities.To_Entity.Insert (Entity.Signature, Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Task_Types.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      if not Decl.F_Definition.Is_Null then
         Process_Children (Decl.F_Definition.F_Public_Part, Entity);

         if GNATdoc.Options.Frontend_Options.Generate_Private then
            Process_Children (Decl.F_Definition.F_Private_Part, Entity);
         end if;
      end if;
   end Process_Task_Decl;

   -----------------
   -- RST_Profile --
   -----------------

   function RST_Profile
     (Node : Libadalang.Analysis.Subp_Spec'Class)
      return VSS.Strings.Virtual_String
   is
      Params  : constant Libadalang.Analysis.Params'Class :=
        Node.F_Subp_Params;
      Returns : constant Libadalang.Analysis.Type_Expr'Class :=
        Node.F_Subp_Returns;
      First   : Boolean := True;

   begin
      return Result : VSS.Strings.Virtual_String do
         case Node.F_Subp_Kind is
            when Ada_Subp_Kind_Function =>
               Result.Append ("function ");
            when Ada_Subp_Kind_Procedure =>
               Result.Append ("procedure ");
         end case;

         Result.Append
           (VSS.Strings.Conversions.To_Virtual_String
              (Node.F_Subp_Name.P_Canonical_Text));

         if not Params.Is_Null then
            Result.Append (" (");

            for Param of Params.F_Params loop
               declare
                  Ids            : constant Defining_Name_List := Param.F_Ids;
                  Type_Decl_Node : constant Type_Expr := Param.F_Type_Expr;
                  Type_Name      : VSS.Strings.Virtual_String;

               begin
                  case Type_Decl_Node.Kind is
                     when Ada_Anonymous_Type =>
                        declare
                           Type_Def_Node : constant Type_Def :=
                             Type_Decl_Node.As_Anonymous_Type.F_Type_Decl
                               .F_Type_Def;

                        begin
                           case Type_Def_Node.Kind is
                              when Ada_Type_Access_Def =>
                                 Type_Name :=
                                   VSS.Strings.To_Virtual_String
                                     (Type_Def_Node.As_Type_Access_Def
                                        .F_Subtype_Indication.F_Name
                                          .P_Referenced_Defining_Name
                                            .P_Fully_Qualified_Name);

                              when Ada_Access_To_Subp_Def =>
                                 Type_Name := "access subprogram";

                              when others =>
                                 raise Program_Error;
                                 --  Should not happened.
                           end case;
                        end;

                     when Ada_Subtype_Indication =>
                        Type_Name :=
                          VSS.Strings.To_Virtual_String
                            (Type_Decl_Node.As_Subtype_Indication.F_Name
                               .P_Referenced_Defining_Name
                                 .P_Fully_Qualified_Name);

                     when others =>
                        raise Program_Error;
                        --  Should not happened.
                  end case;

                  for Id of Ids loop
                     if First then
                        First := False;

                     else
                        Result.Append ("; ");
                     end if;

                     Result.Append
                       (VSS.Strings.To_Virtual_String (Id.F_Name.Text));
                     Result.Append (" : ");
                     Result.Append (Type_Name);
                  end loop;
               end;
            end loop;

            Result.Append (")");
         end if;

         if not Returns.Is_Null then
            Result.Append (" return ");

            case Returns.Kind is
               when Ada_Subtype_Indication =>
                  Result.Append
                    (VSS.Strings.To_Virtual_String
                       (Returns.P_Type_Name.P_Referenced_Defining_Name
                        .P_Fully_Qualified_Name));

               when Ada_Anonymous_Type =>
                  Result.Append
                    (VSS.Strings.To_Virtual_String
                       (Returns.As_Anonymous_Type.F_Type_Decl
                        .F_Type_Def.As_Type_Access_Def.F_Subtype_Indication
                        .P_Type_Name
                        .P_Referenced_Defining_Name
                        .P_Fully_Qualified_Name));

               when others =>
                  raise Program_Error;
            end case;
         end if;
      end return;
   end RST_Profile;

   ---------------
   -- Signature --
   ---------------

   function Signature (Name : Defining_Name'Class) return Virtual_String is
   begin
      if Name.Unit = Name.P_Standard_Unit then
         return Empty_Virtual_String;
      end if;

      return Result : Virtual_String :=
        To_Virtual_String (Name.P_Unique_Identifying_Name)
      do
         case Name.P_Basic_Decl.Kind is
            when Ada_Package_Body | Ada_Subp_Body | Ada_Expr_Function
               | Ada_Subp_Renaming_Decl | Ada_Protected_Body | Ada_Entry_Body
            =>
               Result.Append ('$');

            when Ada_Generic_Subp_Instantiation =>
               Result.Append (To_Virtual_String (Name.Full_Sloc_Image));
               --  ??? LAL: bug in P_Unique_Identifying_Name for generic
               --  subprogram instantiations

            when Ada_Package_Decl | Ada_Type_Decl | Ada_Abstract_Subp_Decl
               | Ada_Subp_Decl | Ada_Null_Subp_Decl
               | Ada_Generic_Package_Instantiation
               | Ada_Generic_Package_Internal
               | Ada_Generic_Subp_Internal
               | Ada_Object_Decl
               | Ada_Number_Decl
               | Ada_Subtype_Decl
               | Ada_Exception_Decl
               | Ada_Single_Task_Type_Decl | Ada_Task_Type_Decl
               | Ada_Single_Protected_Decl | Ada_Protected_Type_Decl
               | Ada_Entry_Decl
               | Ada_Concrete_Formal_Subp_Decl
            =>
               null;

            when others =>
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error,
                  Image (Name) & ": signature of "
                  & Image (Name.P_Basic_Decl)
                  & " => " & VSS.Strings.Conversions.To_UTF_8_String (Result));

         end case;
      end return;
   end Signature;

end GNATdoc.Frontend;
