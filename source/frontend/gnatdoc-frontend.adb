------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2025, AdaCore                     --
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

with GNATdoc.Utilities;
with Libadalang.Common;

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

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

   use type GNATdoc.Entities.Entity_Information_Access;

   procedure Process_Package_Decl
     (Node      : Package_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Package_Body
     (Node      : Package_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access);

   procedure Process_Classic_Subp_Decl
     (Node       : Classic_Subp_Decl'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access;
      Global     : GNATdoc.Entities.Entity_Information_Access;
      In_Private : Boolean);

   procedure Process_Base_Subp_Body
     (Node       : Base_Subp_Body'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access;
      Global     : GNATdoc.Entities.Entity_Information_Access;
      In_Private : Boolean);
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
     (Parent     : Ada_Node'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access;
      In_Private : Boolean);
   --  Process children nodes, filter out important nodes, and dispatch to
   --  corresponding documentation extraction and entity creation subprograms.

   procedure Analyze_Primitive_Operations
     (Node   : Type_Decl'Class;
      Entity : in out GNATdoc.Entities.Entity_Information);
   --  Process delaration of the tagged/interface type and constructs sets of
   --  dispatching operations.

   procedure Analyze_Non_Dispatching_Method
     (Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Belongs   : GNATdoc.Entities.Entity_Information_Access;
      Entity    : not null GNATdoc.Entities.Entity_Information_Access;
      Node      : Basic_Decl'Class;
      Spec      : Subp_Spec);
   --  Analyze subprogram to detect cases when it is available via prefixed
   --  notation.

   procedure Construct_Generic_Formals
     (Entity  : not null GNATdoc.Entities.Entity_Information_Access;
      Formals : Generic_Formal_Part);
   --  Constructs entities for formal parameters of the generic from the
   --  structured comment of the generic.

   function Signature
     (Name : Defining_Name'Class) return GNATdoc.Entities.Entity_Signature;
   --  Computes unique signature of the given entity.

   function Subprogram_Primary_View
     (Node : Basic_Decl'Class) return Basic_Decl;
   --  Returns subprogram specification node when given node is subprogram body
   --  is any. Returns given node overwise.

   procedure Check_Undocumented
     (Entity : not null GNATdoc.Entities.Entity_Information_Access);
   --  Check whether entiry and all components of the entity are documented.
   --  Generate warnings when they are enabled.

   function RST_Profile
     (Node : Libadalang.Analysis.Subp_Spec'Class)
      return VSS.Strings.Virtual_String;

   procedure Resolve_Belongs_To
     (Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Belongs   : out GNATdoc.Entities.Entity_Information_Access;
      Entity    : not null GNATdoc.Entities.Entity_Information_Access);
   --  Process `@belongs-to` tag.

   function Create_Entity
     (Enclosing     : GNATdoc.Entities.Entity_Information_Access;
      Kind          : GNATdoc.Entities.Entity_Kind;
      Defining_Name : Libadalang.Analysis.Defining_Name'Class)
      return not null GNATdoc.Entities.Entity_Information_Access;
   --  Creates entity and link it with enclosing

   Methods : GNATdoc.Entities.Entity_Reference_Sets.Set;
   --  All methods was found during processing of compilation units.

   ------------------------------------
   -- Analyze_Non_Dispatching_Method --
   ------------------------------------

   procedure Analyze_Non_Dispatching_Method
     (Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Belongs   : GNATdoc.Entities.Entity_Information_Access;
      Entity    : not null GNATdoc.Entities.Entity_Information_Access;
      Node      : Basic_Decl'Class;
      Spec      : Subp_Spec) is
   begin
      if Spec.F_Subp_Params.Is_Null then
         --  Parameterless subprogram.

         return;
      end if;

      declare
         Parameter                 : constant Param_Spec :=
           Spec.F_Subp_Params.F_Params.First_Child.As_Param_Spec;
         Parameter_Type_Expression : constant Type_Expr :=
           Parameter.F_Type_Expr;
         Parameter_Type_Name       : Libadalang.Analysis.Name;
         Parameter_Type            : Base_Type_Decl;
         Subprogram_Scope          : Declarative_Part;
         Parameter_Type_Scope      : Declarative_Part;

      begin
         if Parameter_Type_Expression.Kind = Ada_Subtype_Indication then
            Parameter_Type_Name :=
              Parameter_Type_Expression.As_Subtype_Indication.F_Name;

         elsif Parameter_Type_Expression.As_Anonymous_Type.F_Type_Decl
                 .F_Type_Def.Kind = Ada_Access_To_Subp_Def
         then
            --  First parameter has an access to subprogram type, it is not
            --  a prefix-callable subprogram.

            return;

         else
            pragma Assert
                     (Parameter_Type_Expression.Kind = Ada_Anonymous_Type);

            Parameter_Type_Name :=
              Parameter_Type_Expression.As_Anonymous_Type.F_Type_Decl
                .F_Type_Def.As_Type_Access_Def.F_Subtype_Indication.F_Name;
         end if;

         if Parameter_Type_Name.Kind = Ada_Attribute_Ref then
            --  Dereference attributes ('Class/'Base)

            Parameter_Type_Name :=
              Parameter_Type_Name.As_Attribute_Ref.F_Prefix;
         end if;

         Parameter_Type := Parameter_Type_Name.P_Name_Designated_Type;

         Subprogram_Scope := Node.P_Declarative_Scope;
         --  Is null for subprogram as compilation unit.

         Parameter_Type_Scope := Parameter_Type.P_Declarative_Scope;
         --  Is null for formal parameter of the generic.

         if Parameter_Type.P_Is_Tagged_Type
           and then not Subprogram_Scope.Is_Null
           and then not Parameter_Type_Scope.Is_Null
           and then Subprogram_Scope.P_Semantic_Parent
                      = Parameter_Type_Scope.P_Semantic_Parent
           and then GNATdoc.Entities.To_Entity.Contains
                      (Signature
                         (Parameter_Type_Name.P_Referenced_Defining_Name))
         then
            declare
               Belongs_Reference : constant
                 GNATdoc.Entities.Entity_Reference :=
                   ((To_Virtual_String
                      (Parameter_Type_Name.P_Referenced_Defining_Name
                         .P_Canonical_Fully_Qualified_Name),
                  Signature
                    (Parameter_Type_Name.P_Referenced_Defining_Name)));
               Belongs_Entity    : constant not null
                 GNATdoc.Entities.Entity_Information_Access :=
                   (if Belongs = null
                      then GNATdoc.Entities.To_Entity
                             (Belongs_Reference.Signature)
                      else Belongs);

            begin
               Entity.Is_Method := True;

               if Belongs = null then
                  Entity.Belongs := Belongs_Reference;
                  Belongs_Entity.Belong_Entities.Insert (Entity.Reference);
                  Belongs_Entity.Belongs_Subprograms.Insert (Entity.Reference);

                  Enclosing.Belong_Entities.Exclude (Entity.Reference);
                  Enclosing.Belongs_Subprograms.Exclude (Entity.Reference);
                  --  Subprograms declared in private part can be excluded
                  --  from the set of subprograms, so use `Exclude` to prevent
                  --  raise of exception.
               end if;

               Belongs_Entity.Prefix_Callable_Declared.Insert
                 (Entity.Reference);
            end;
         end if;
      end;
   end Analyze_Non_Dispatching_Method;

   ------------------------------
   -- Analyze_Class_Operations --
   ------------------------------

   procedure Analyze_Primitive_Operations
     (Node   : Type_Decl'Class;
      Entity : in out GNATdoc.Entities.Entity_Information)
   is
      use type Libadalang.Text.Unbounded_Text_Type;

      Primitives : constant Basic_Decl_Array := Node.P_Get_Primitives;

   begin
      for Subprogram of Primitives loop
         --  Libadalang synthesize "/=" operator, however, there is no such
         --  operator in Ada, so ignore it.

         if not (Subprogram.Kind = Ada_Synthetic_Subp_Decl
                   and Subprogram.P_Defining_Name.P_Canonical_Text = """/=""")
         then
            declare
               Subprogram_View : constant Basic_Decl :=
                 Subprogram_Primary_View (Subprogram);
               Subprogram_Ref  : constant GNATdoc.Entities.Entity_Reference :=
                 (To_Virtual_String (Subprogram_View.P_Fully_Qualified_Name),
                  Signature (Subprogram_View.P_Defining_Name));

            begin
               Methods.Include (Subprogram_Ref);
               --  Subprogram's entity is not created yet, store it to complete
               --  processing later.

               if Node.P_Is_Inherited_Primitive (Subprogram) then
                  Entity.Dispatching_Inherited.Include (Subprogram_Ref);

               else
                  declare
                     Decls : constant Basic_Decl_Array :=
                       Subprogram.P_Base_Subp_Declarations;

                  begin
                     --  Classify whether subprogram is declared first time or
                     --  overrides subprogram of the parent/progenitor type.

                     if Decls'Length > 1 then
                        Entity.Dispatching_Overrided.Include (Subprogram_Ref);

                     else
                        Entity.Dispatching_Declared.Include (Subprogram_Ref);
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;
   end Analyze_Primitive_Operations;

   ------------------------
   -- Check_Undocumented --
   ------------------------

   procedure Check_Undocumented
     (Entity : not null GNATdoc.Entities.Entity_Information_Access) is
   begin
      if GNATdoc.Configuration.Provider.Warnings_Enabled then
         GNATdoc.Comments.Undocumented_Checker.Check_Undocumented
           (Location      => Entity.Location,
            Name          => Entity.Name,
            Documentation => Entity.Documentation,
            Messages      => Entity.Messages);

         for Message of Entity.Messages loop
            GNATdoc.Messages.Report_Warning (Message);
         end loop;
      end if;
   end Check_Undocumented;

   -------------------------------
   -- Construct_Generic_Formals --
   -------------------------------

   procedure Construct_Generic_Formals
     (Entity  : not null GNATdoc.Entities.Entity_Information_Access;
      Formals : Generic_Formal_Part)
   is
      procedure Create_Formal
        (Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
         Name      : Libadalang.Analysis.Defining_Name'Class);
      --  Extract documentation for formal with given name.

      -------------------
      -- Create_Formal --
      -------------------

      procedure Create_Formal
        (Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
         Name      : Libadalang.Analysis.Defining_Name'Class)
      is
         Entity :
           constant not null GNATdoc.Entities.Entity_Information_Access :=
             Create_Entity
               (Enclosing     => Enclosing,
                Kind          => GNATdoc.Entities.Ada_Formal,
                Defining_Name => Name);

      begin
         GNATdoc.Comments.Extractor.Extract_Formal_Section
           (Documentation => Enclosing.Documentation,
            Name          => Name,
            Into          => Entity.Documentation);

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
                  Create_Formal (Entity, Formal_Name);
               end;

            when Ada_Generic_Formal_Subp_Decl =>
               Create_Formal
                 (Entity,
                  Item.As_Generic_Formal_Subp_Decl.F_Decl
                    .As_Concrete_Formal_Subp_Decl.F_Subp_Spec.F_Subp_Name);

            when Ada_Generic_Formal_Obj_Decl =>
               for Id of
                 Item.As_Generic_Formal_Obj_Decl.F_Decl.As_Object_Decl.F_Ids
               loop
                  Create_Formal (Entity, Id);
               end loop;

            when Ada_Generic_Formal_Package =>
               Create_Formal
                 (Entity,
                  Item.As_Generic_Formal_Package.F_Decl
                    .As_Generic_Package_Instantiation.F_Name);

            when others =>
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error, Image (Item));
         end case;
      end loop;
   end Construct_Generic_Formals;

   -------------------
   -- Create_Entity --
   -------------------

   function Create_Entity
     (Enclosing     : GNATdoc.Entities.Entity_Information_Access;
      Kind          : GNATdoc.Entities.Entity_Kind;
      Defining_Name : Libadalang.Analysis.Defining_Name'Class)
      return not null GNATdoc.Entities.Entity_Information_Access is
   begin
      return Result : constant not null
        GNATdoc.Entities.Entity_Information_Access :=
          new GNATdoc.Entities.Entity_Information'
            (Kind           => Kind,
             Location       => GNATdoc.Utilities.Location (Defining_Name),
             Name           => To_Virtual_String (Defining_Name.F_Name.Text),
             Qualified_Name =>
               To_Virtual_String (Defining_Name.P_Fully_Qualified_Name),
             Signature      => Signature (Defining_Name),
             Enclosing      => Enclosing.Signature,
             Documentation  => <>,
             others         => <>)
      do
         GNATdoc.Entities.To_Entity.Insert (Result.Signature, Result);

         Enclosing.Entities.Insert (Result);
         Enclosing.Belong_Entities.Insert (Result.Reference);
      end return;
   end Create_Entity;

   -----------------
   -- Postprocess --
   -----------------

   procedure Postprocess is

      procedure Establish_Parent_Derived_Relation
        (Parent  : GNATdoc.Entities.Entity_Reference;
         Derived : not null GNATdoc.Entities.Entity_Information_Access);

      procedure Establish_Progenitor_Relation
        (Progenitor : GNATdoc.Entities.Entity_Reference;
         Derived    : not null GNATdoc.Entities.Entity_Information_Access);

      procedure Build_Non_Dispatching_Methods
        (Entity : not null GNATdoc.Entities.Entity_Information_Access);

      -----------------------------------
      -- Build_Non_Dispatching_Methods --
      -----------------------------------

      procedure Build_Non_Dispatching_Methods
        (Entity : not null GNATdoc.Entities.Entity_Information_Access) is
      begin
         if not Entity.Prefix_Callable_Inherited.Is_Empty then
            --  Set of prefix-callable subprograms was built.

            return;
         end if;

         --  Build sets of subprograms for progenitors and parent types.

         for Item of Entity.Progenitor_Types loop
            if GNATdoc.Entities.To_Entity.Contains (Item.Signature) then
               Build_Non_Dispatching_Methods
                 (GNATdoc.Entities.To_Entity (Item.Signature));
            end if;
         end loop;

         if not Entity.Parent_Type.Signature.Image.Is_Empty
           and then GNATdoc.Entities.To_Entity.Contains
                      (Entity.Parent_Type.Signature)
         then
            Build_Non_Dispatching_Methods
              (GNATdoc.Entities.To_Entity (Entity.Parent_Type.Signature));
         end if;

         --  Build set of subprograms for given type.

         for Item of Entity.Progenitor_Types loop
            if GNATdoc.Entities.To_Entity.Contains (Item.Signature) then
               Entity.Prefix_Callable_Inherited.Union
                 (GNATdoc.Entities.To_Entity
                    (Item.Signature).Prefix_Callable_Declared);
               Entity.Prefix_Callable_Inherited.Union
                 (GNATdoc.Entities.To_Entity
                    (Item.Signature).Prefix_Callable_Inherited);
            end if;
         end loop;

         if not Entity.Parent_Type.Signature.Image.Is_Empty
           and then GNATdoc.Entities.To_Entity.Contains
                      (Entity.Parent_Type.Signature)
         then
            Entity.Prefix_Callable_Inherited.Union
              (GNATdoc.Entities.To_Entity
                 (Entity.Parent_Type.Signature).Prefix_Callable_Declared);
            Entity.Prefix_Callable_Inherited.Union
              (GNATdoc.Entities.To_Entity
                 (Entity.Parent_Type.Signature).Prefix_Callable_Inherited);
         end if;
      end Build_Non_Dispatching_Methods;

      ---------------------------------------
      -- Establish_Parent_Derived_Relation --
      ---------------------------------------

      procedure Establish_Parent_Derived_Relation
        (Parent  : GNATdoc.Entities.Entity_Reference;
         Derived : not null GNATdoc.Entities.Entity_Information_Access)
      is
         Parent_Entity : GNATdoc.Entities.Entity_Information_Access;

      begin
         if GNATdoc.Entities.To_Entity.Contains (Parent.Signature) then
            Parent_Entity := GNATdoc.Entities.To_Entity (Parent.Signature);
         end if;

         Derived.All_Parent_Types.Include (Parent);

         if Parent_Entity /= null then
            Parent_Entity.All_Derived_Types.Include (Derived.Reference);

            if GNATdoc.Entities.To_Entity.Contains
                 (Parent_Entity.Parent_Type.Signature)
            then
               Establish_Parent_Derived_Relation
                 (Parent  => Parent_Entity.Parent_Type,
                  Derived => Derived);
            end if;
         end if;
      end Establish_Parent_Derived_Relation;

      -----------------------------------
      -- Establish_Progenitor_Relation --
      -----------------------------------

      procedure Establish_Progenitor_Relation
        (Progenitor : GNATdoc.Entities.Entity_Reference;
         Derived    : not null GNATdoc.Entities.Entity_Information_Access)
      is
         Progenitor_Entity : GNATdoc.Entities.Entity_Information_Access;

      begin
         if GNATdoc.Entities.To_Entity.Contains (Progenitor.Signature) then
            Progenitor_Entity :=
              GNATdoc.Entities.To_Entity (Progenitor.Signature);
         end if;

         Derived.All_Progenitor_Types.Include (Progenitor);

         if Progenitor_Entity /= null then
            for Progenitor of Progenitor_Entity.Progenitor_Types loop
               Establish_Progenitor_Relation
                 (Progenitor => Progenitor,
                  Derived    => Derived);
            end loop;
         end if;
      end Establish_Progenitor_Relation;

   begin
      --  Build inheritance information

      for Item of GNATdoc.Entities.Globals.Tagged_Types loop
         declare
            Entity : constant not null
              GNATdoc.Entities.Entity_Information_Access :=
                GNATdoc.Entities.To_Entity (Item.Signature);

         begin
            if not Entity.Parent_Type.Signature.Image.Is_Empty then
               --  Construct references between parent/derived types.

               if GNATdoc.Entities.To_Entity.Contains
                    (Entity.Parent_Type.Signature)
               then
                  GNATdoc.Entities.To_Entity
                    (Entity.Parent_Type.Signature).Derived_Types.Insert
                      (Item.Reference);
               end if;

               Establish_Parent_Derived_Relation
                 (Parent => Entity.Parent_Type, Derived => Entity);
            end if;

            for Progenitor of Entity.Progenitor_Types loop
               Establish_Progenitor_Relation
                 (Progenitor => Progenitor,
                  Derived    => Entity);
            end loop;
         end;
      end loop;

      for Item of GNATdoc.Entities.Globals.Interface_Types loop
         declare
            Entity : constant not null
              GNATdoc.Entities.Entity_Information_Access :=
                GNATdoc.Entities.To_Entity (Item.Signature);

         begin
            for Progenitor of Entity.Progenitor_Types loop
               Establish_Progenitor_Relation
                 (Progenitor => Progenitor,
                  Derived    => Entity);
            end loop;
         end;
      end loop;

      --  Build list of all non-dispatching operations.

      for Item of GNATdoc.Entities.Globals.Interface_Types loop
         Build_Non_Dispatching_Methods (Item);
      end loop;

      for Item of GNATdoc.Entities.Globals.Tagged_Types loop
         Build_Non_Dispatching_Methods (Item);
      end loop;

      --  Mark all subprograms that are documented as part of the class's
      --  documentation.

      for Method of Methods loop
         if GNATdoc.Entities.To_Entity.Contains (Method.Signature) then
            declare
               Entity    : constant
                 GNATdoc.Entities.Entity_Information_Access :=
                   GNATdoc.Entities.To_Entity (Method.Signature);
               Enclosing : constant
                 GNATdoc.Entities.Entity_Information_Access :=
                   GNATdoc.Entities.To_Entity (Entity.Enclosing);
               Belongs   : constant
                 GNATdoc.Entities.Entity_Information_Access :=
                   (if Entity.Belongs.Signature.Image.Is_Empty
                      then null
                      else GNATdoc.Entities.To_Entity
                             (Entity.Belongs.Signature));
               --  `Owner_Class` might not be filled for subprograms excluded
               --  from generation for some reason

            begin
               if Enclosing.Belong_Entities.Contains (Entity.Reference)
                 and Belongs /= null
               then
                  Enclosing.Belong_Entities.Delete (Entity.Reference);
                  Enclosing.Belongs_Subprograms.Delete (Entity.Reference);

                  Belongs.Belong_Entities.Insert (Entity.Reference);
                  Belongs.Belongs_Subprograms.Insert (Entity.Reference);
               end if;

               Entity.Is_Method := True;
            end;
         end if;
      end loop;
   end Postprocess;

   -----------------------------
   -- Process_Access_Type_Def --
   -----------------------------

   procedure Process_Access_Type_Def
     (Node      : Type_Decl'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Other_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Other_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Array_Types.Insert (Entity);
      Check_Undocumented (Entity);
   end Process_Array_Type_Def;

   ----------------------------
   -- Process_Base_Subp_Body --
   ----------------------------

   procedure Process_Base_Subp_Body
     (Node       : Base_Subp_Body'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access;
      Global     : GNATdoc.Entities.Entity_Information_Access;
      In_Private : Boolean)
   is
      Name    : constant Defining_Name := Node.F_Subp_Spec.F_Subp_Name;
      Entity  : constant not null GNATdoc.Entities.Entity_Information_Access :=
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          =>
             (case Node.F_Subp_Spec.F_Subp_Kind is
                 when Ada_Subp_Kind_Function  =>
                   GNATdoc.Entities.Ada_Function,
                 when Ada_Subp_Kind_Procedure =>
                   GNATdoc.Entities.Ada_Procedure),
           Defining_Name => Name);
      Belongs : GNATdoc.Entities.Entity_Information_Access;

   begin
      Entity.RST_Profile := RST_Profile (Node.F_Subp_Spec);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);

      Resolve_Belongs_To
        (Enclosing => Enclosing,
         Belongs   => Belongs,
         Entity    => Entity);

      if not In_Private
        or GNATdoc.Options.Frontend_Options.Generate_Private
      then
         Enclosing.Subprograms.Insert (Entity);

         if Belongs = null then
            Enclosing.Belongs_Subprograms.Insert (Entity.Reference);

         else
            Enclosing.Belong_Entities.Delete (Entity.Reference);

            Belongs.Belong_Entities.Insert (Entity.Reference);
            Belongs.Belongs_Subprograms.Insert (Entity.Reference);

            Entity.Belongs := Belongs.Reference;
         end if;

         if Global /= null
           and GNATdoc.Entities.Globals'Access /= Enclosing
         then
            Global.Subprograms.Insert (Entity);
         end if;
      end if;

      --  Detect whether subprogram can be called by "prefix notation".

      if Subprogram_Primary_View (Node) = Node then
         --  Analyze subprogram body when there is no separate subprogram
         --  specification.

         Analyze_Non_Dispatching_Method
           (Enclosing => Enclosing,
            Belongs   => Belongs,
            Entity    => Entity,
            Node      => Node,
            Spec      => Node.F_Subp_Spec);
      end if;

      Check_Undocumented (Entity);
   end Process_Base_Subp_Body;

   ----------------------
   -- Process_Children --
   ----------------------

   procedure Process_Children
     (Parent     : Ada_Node'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access;
      In_Private : Boolean)
   is

      function Process_Node (Node : Ada_Node'Class) return Visit_Status;

      ------------------
      -- Process_Node --
      ------------------

      function Process_Node (Node : Ada_Node'Class) return Visit_Status is
      begin
         if not GNATdoc.Options.Frontend_Options.Generate_Private
           and In_Private
         then
            --  Dispatching subprograms for tagged types may be declared inside
            --  private part of the package, so process some nodes even when
            --  documentation generation for private parts is disabled.

            case Node.Kind is
               when Ada_Private_Part | Ada_Ada_Node_List =>
                  return Into;

               when Ada_Attribute_Def_Clause
                  | Ada_Concrete_Type_Decl
                  | Ada_Enum_Rep_Clause
                  | Ada_Exception_Decl
                  | Ada_Generic_Package_Instantiation
                  | Ada_Incomplete_Tagged_Type_Decl
                  | Ada_Incomplete_Type_Decl
                  | Ada_Number_Decl
                  | Ada_Object_Decl
                  | Ada_Package_Renaming_Decl
                  | Ada_Pragma_Node
                  | Ada_Protected_Type_Decl
                  | Ada_Record_Rep_Clause
                  | Ada_Subtype_Decl
                  | Ada_Task_Type_Decl
                  | Ada_Use_Package_Clause
                  | Ada_Use_Type_Clause
               =>
                  return Over;

               when Ada_Generic_Subp_Instantiation =>
                  --  ??? It is not clear should it be processed or not.

                  return Over;

               when Ada_Abstract_Subp_Decl
                  | Ada_Expr_Function
                  | Ada_Null_Subp_Decl
                  | Ada_Subp_Decl
                  | Ada_Subp_Renaming_Decl
               =>
                  null;

               when others =>
                  GNATdoc.Messages.Raise_Not_Implemented (Node.Image);
            end case;
         end if;

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

            when Ada_Incomplete_Type_Decl | Ada_Incomplete_Tagged_Type_Decl =>
               --  Nothing to do for incomplete types.

               return Over;

            when Ada_Subp_Decl =>
               Process_Classic_Subp_Decl
                 (Node.As_Subp_Decl, Enclosing, null, In_Private);

               return Over;

            when Ada_Abstract_Subp_Decl =>
               Process_Classic_Subp_Decl
                 (Node.As_Abstract_Subp_Decl, Enclosing, null, In_Private);

               return Over;

            when Ada_Null_Subp_Decl =>
               Process_Base_Subp_Body
                 (Node.As_Null_Subp_Decl, Enclosing, null, In_Private);

               return Over;

            when Ada_Subp_Body =>
               Process_Base_Subp_Body
                 (Node.As_Subp_Body, Enclosing, null, In_Private);

               return Over;

            when Ada_Expr_Function =>
               Process_Base_Subp_Body
                 (Node.As_Expr_Function, Enclosing, null, In_Private);

               return Over;

            when Ada_Generic_Subp_Decl =>
               Process_Generic_Subp_Decl
                 (Node.As_Generic_Subp_Decl, Enclosing, null);

               return Over;

            when Ada_Generic_Package_Decl =>
               Process_Generic_Package_Decl
                 (Node.As_Generic_Package_Decl,
                  GNATdoc.Entities.Globals'Access);

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
                 (Node.As_Subp_Renaming_Decl, Enclosing, null, In_Private);

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
               Process_Package_Decl
                 (Node.As_Package_Decl,
                  GNATdoc.Entities.Globals'Access);

               return Over;

            when Ada_Package_Body =>
               Process_Package_Body
                 (Node.As_Package_Body,
                  GNATdoc.Entities.Globals'Access);

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

            GNATdoc.Messages.Report_Internal_Error
              (GNATdoc.Utilities.Location (Node), E);

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
     (Node       : Classic_Subp_Decl'Class;
      Enclosing  : not null GNATdoc.Entities.Entity_Information_Access;
      Global     : GNATdoc.Entities.Entity_Information_Access;
      In_Private : Boolean)
   is
      Spec    : constant Subp_Spec     := Node.F_Subp_Spec;
      Name    : constant Defining_Name := Spec.F_Subp_Name;
      Entity  : constant not null GNATdoc.Entities.Entity_Information_Access :=
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          =>
             (case Spec.F_Subp_Kind is
                 when Ada_Subp_Kind_Function  =>
                   GNATdoc.Entities.Ada_Function,
                 when Ada_Subp_Kind_Procedure =>
                   GNATdoc.Entities.Ada_Procedure),
           Defining_Name => Name);
      Belongs : GNATdoc.Entities.Entity_Information_Access;

   begin
      Entity.RST_Profile := RST_Profile (Spec);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);

      Resolve_Belongs_To (Enclosing, Belongs, Entity);

      if not In_Private
        or else GNATdoc.Options.Frontend_Options.Generate_Private
      then
         Enclosing.Subprograms.Insert (Entity);

         if Belongs = null then
            Enclosing.Belongs_Subprograms.Insert (Entity.Reference);

         else
            Enclosing.Belong_Entities.Delete (Entity.Reference);

            Belongs.Belong_Entities.Insert (Entity.Reference);
            Belongs.Belongs_Subprograms.Insert (Entity.Reference);

            Entity.Belongs := Belongs.Reference;
         end if;

         if Global /= null
           and GNATdoc.Entities.Globals'Access /= Enclosing
         then
            Global.Subprograms.Insert (Entity);
         end if;
      end if;

      --  Detect whether subprogram can be called by "prefix notation".

      Analyze_Non_Dispatching_Method
        (Enclosing => Enclosing,
         Belongs   => Belongs,
         Entity    => Entity,
         Node      => Node,
         Spec      => Spec);

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
                  GNATdoc.Entities.Globals'Access,
                  False);

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
                     GNATdoc.Entities.Globals'Access,
                     False);
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

            when Ada_Generic_Package_Instantiation
               | Ada_Generic_Subp_Instantiation
            =>
               Process_Generic_Instantiation
                 (Node.As_Generic_Instantiation,
                  GNATdoc.Entities.Globals'Access,
                  GNATdoc.Entities.Globals'Access);

               return Over;

            when others =>
               Ada.Text_IO.Put_Line (Image (Node));

               return Into;
         end case;

      exception
         when E : others =>
            GNATdoc.Messages.Report_Internal_Error
              (GNATdoc.Utilities.Location (Node), E);

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Tagged_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);

      if Def.F_Has_With_Private or not Def.F_Record_Extension.Is_Null then
         Enclosing.Tagged_Types.Insert (Entity);
         GNATdoc.Entities.Globals.Tagged_Types.Insert (Entity);

         declare
            Parent_Decl : Base_Type_Decl :=
              Def.F_Subtype_Indication.F_Name.P_Referenced_Decl
                .As_Base_Type_Decl;
            Parent_Name : Defining_Name;
            Parent_Def  : Type_Def;

         begin
            --  Unwind sequence of subtypes if any

            loop
               exit when Parent_Decl.Kind /= Ada_Subtype_Decl;

               Parent_Decl := @.As_Subtype_Decl.P_Get_Type;
            end loop;

            Parent_Name :=
              Def.F_Subtype_Indication.F_Name.P_Referenced_Defining_Name;

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

         Analyze_Primitive_Operations (Node, Entity.all);

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
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
                Create_Entity
                  (Enclosing     => Enclosing,
                   Kind          => GNATdoc.Entities.Ada_Exception,
                   Defining_Name => Name);

         begin
            Extract
              (Node          => Node,
               Options       => GNATdoc.Options.Extractor_Options,
               Documentation => Entity.Documentation,
               Messages      => Entity.Messages);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind =>
             (case Node.Kind is
                 when Ada_Generic_Package_Instantiation =>
                   GNATdoc.Entities.Ada_Generic_Package_Instantiation,
                 when Ada_Generic_Subp_Instantiation =>
                   GNATdoc.Entities.Ada_Generic_Subprogram_Instantiation,
                 when others => raise Program_Error),
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Generic_Instantiations.Insert (Entity);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Generic_Instantiations.Insert (Entity);
      end if;

      Entity.RSTPT_Instpkg :=
        VSS.Strings.To_Virtual_String
          (Node.P_Designated_Generic_Decl.P_Fully_Qualified_Name);

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          =>
             (case Spec.F_Subp_Kind is
                 when Ada_Subp_Kind_Function  =>
                   GNATdoc.Entities.Ada_Function,
                 when Ada_Subp_Kind_Procedure =>
                   GNATdoc.Entities.Ada_Procedure),
           Defining_Name => Name);

   begin
      Entity.RST_Profile := RST_Profile (Spec);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Subprograms.Insert (Entity);
      Enclosing.Belongs_Subprograms.Insert (Entity.Reference);

      if Global /= null and GNATdoc.Entities.Globals'Access /= Enclosing then
         Global.Subprograms.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Construct_Generic_Formals (Entity, Node.F_Formal_Part);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Entity.Is_Private :=
        (Node.Parent.Kind = Ada_Library_Item
           and then Node.Parent.As_Library_Item.F_Has_Private);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Packages.Insert (Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Package_Decl.F_Public_Part, Entity, False);
      Process_Children (Node.F_Package_Decl.F_Private_Part, Entity, True);

      Construct_Generic_Formals (Entity, Node.F_Formal_Part);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Interface_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Interface_Types.Insert (Entity);
      GNATdoc.Entities.Globals.Interface_Types.Insert (Entity);

      for Item of Def.F_Interfaces loop
         Entity.Progenitor_Types.Insert
           ((VSS.Strings.To_Virtual_String
            (Item.P_Referenced_Defining_Name.P_Fully_Qualified_Name),
            Signature (Item.P_Referenced_Defining_Name)));
      end loop;

      Analyze_Primitive_Operations (Node, Entity.all);

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
                Create_Entity
                  (Enclosing     => Enclosing,
                   Kind          => GNATdoc.Entities.Ada_Named_Number,
                   Defining_Name => Name);

         begin
            if not Node.F_Expr.Is_Null then
               Entity.RSTPT_Defval :=
                 VSS.Strings.To_Virtual_String (Node.F_Expr.Text);
            end if;

            Extract
              (Node          => Node,
               Options       => GNATdoc.Options.Extractor_Options,
               Documentation => Entity.Documentation,
               Messages      => Entity.Messages);
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
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Objects_Parent : constant Basic_Decl := Node.P_Parent_Basic_Decl;
      Type_Name      : Defining_Name;
      Type_Signature : GNATdoc.Entities.Entity_Signature;
      Type_Parent    : Basic_Decl;

      RSTPT_Objtype  : VSS.Strings.Virtual_String;
      RSTPT_Defval   : VSS.Strings.Virtual_String;

      Template : constant VSS.Strings.Templates.Virtual_String_Template :=
        "{} : constant {}";

   begin
      case Node.F_Type_Expr.Kind is
         when Ada_Subtype_Indication =>
            Type_Name :=
              Node.F_Type_Expr.As_Subtype_Indication.P_Type_Name
                .P_Referenced_Defining_Name;
            Type_Signature := Signature (Type_Name);
            Type_Parent := Type_Name.P_Parent_Basic_Decl.P_Parent_Basic_Decl;

            RSTPT_Objtype :=
              VSS.Strings.To_Virtual_String (Type_Name.P_Fully_Qualified_Name);

         when Ada_Anonymous_Type =>
            null;

         when others =>
            raise Program_Error;
      end case;

      if not Node.F_Default_Expr.Is_Null then
         RSTPT_Defval :=
           VSS.Strings.To_Virtual_String (Node.F_Default_Expr.Text);
      end if;

      for Name of Node.F_Ids loop
         declare
            Entity  : constant not null
              GNATdoc.Entities.Entity_Information_Access :=
                Create_Entity
                  (Enclosing     => Enclosing,
                   Kind          => GNATdoc.Entities.Ada_Object,
                   Defining_Name => Name);
            Belongs : GNATdoc.Entities.Entity_Information_Access;

         begin
            Entity.RSTPT_Objtype := RSTPT_Objtype;
            Entity.RSTPT_Defval  := RSTPT_Defval;

            Extract
              (Node          => Node,
               Options       => GNATdoc.Options.Extractor_Options,
               Documentation => Entity.Documentation,
               Messages      => Entity.Messages);

            if Node.F_Has_Constant then
               Enclosing.Constants.Insert (Entity);

               Resolve_Belongs_To
                 (Enclosing => Enclosing,
                  Belongs   => Belongs,
                  Entity    => Entity);

               --  If there is not explicitly defined @belongs-to tag, and
               --  type is a "class", and both type and object are declared in
               --  the same package, mark constant object as belongs to type.

               if Belongs = null
                 and Node.F_Type_Expr.Kind = Ada_Subtype_Indication
               then

                  if Type_Parent = Objects_Parent
                    and then GNATdoc.Entities.To_Entity.Contains
                               (Type_Signature)
                    and then GNATdoc.Entities.To_Entity (Type_Signature).Kind
                       in GNATdoc.Entities.Ada_Tagged_Type
                        | GNATdoc.Entities.Ada_Interface_Type
                  then
                     Belongs :=
                       GNATdoc.Entities.To_Entity (Signature (Type_Name));
                  end if;

                  Entity.RSTPT_Objtype :=
                    VSS.Strings.To_Virtual_String
                      (Type_Name.P_Fully_Qualified_Name);
               end if;

               if Belongs = null then
                  Enclosing.Belongs_Constants.Insert (Entity.Reference);

               else
                  Entity.RST_Profile :=
                    Template.Format
                      (VSS.Strings.Formatters.Strings.Image (Entity.Name),
                       VSS.Strings.Formatters.Strings.Image (Belongs.Name));

                  Enclosing.Belong_Entities.Delete (Entity.Reference);
                  Belongs.Belong_Entities.Insert (Entity.Reference);
                  Belongs.Belongs_Constants.Insert (Entity.Reference);
                  Entity.Belongs := Belongs.Reference;
               end if;

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Entity.Is_Private :=
        (Node.Parent.Kind = Ada_Library_Item
           and then Node.Parent.As_Library_Item.F_Has_Private);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Packages.Insert (Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Public_Part, Entity, False);
      Process_Children (Node.F_Private_Part, Entity, True);
   end Process_Package_Decl;

   --------------------------
   -- Process_Package_Body --
   --------------------------

   procedure Process_Package_Body
     (Node      : Package_Body'Class;
      Enclosing : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Name   : constant Defining_Name := Node.F_Package_Name;
      Entity : constant not null GNATdoc.Entities.Entity_Information_Access :=
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Entity.Is_Specification := False;

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Packages.Insert (Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Decls, Entity, True);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Other_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);

      if Node.F_Type_Def.As_Private_Type_Def.F_Has_Tagged then
         Entity.Kind := GNATdoc.Entities.Ada_Tagged_Type;

         Enclosing.Tagged_Types.Insert (Entity);
         GNATdoc.Entities.Globals.Tagged_Types.Insert (Entity);

         Analyze_Primitive_Operations (Node, Entity.all);

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Protected_Types.Insert (Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Packages.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Node.F_Decls, Entity, True);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Entity.Is_Private :=
        (Node.Parent.Kind = Ada_Library_Item
           and then Node.Parent.As_Library_Item.F_Has_Private);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Protected_Types.Insert (Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Protected_Types.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      Process_Children (Definition.F_Public_Part, Entity, False);

      if GNATdoc.Options.Frontend_Options.Generate_Private then
         Process_Children (Definition.F_Private_Part, Entity, True);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Other_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);

      if Node.F_Type_Def.As_Record_Type_Def.F_Has_Tagged then
         Entity.Kind := GNATdoc.Entities.Ada_Tagged_Type;
         Enclosing.Tagged_Types.Insert (Entity);
         GNATdoc.Entities.Globals.Tagged_Types.Insert (Entity);

      else
         Enclosing.Record_Types.Insert (Entity);
      end if;

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Other_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Ada_Other_Type,
           Defining_Name => Name);

   begin
      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);

      Enclosing.Subtypes.Insert (Entity);
      GNATdoc.Entities.Globals.Subtypes.Insert (Entity);

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
        Create_Entity
          (Enclosing     => Enclosing,
           Kind          => GNATdoc.Entities.Undefined,
           Defining_Name => Name);

   begin
      Entity.Is_Private :=
        (Node.Parent.Kind = Ada_Library_Item
           and then Node.Parent.As_Library_Item.F_Has_Private);

      Extract
        (Node          => Node,
         Options       => GNATdoc.Options.Extractor_Options,
         Documentation => Entity.Documentation,
         Messages      => Entity.Messages);
      Enclosing.Task_Types.Insert (Entity);

      if GNATdoc.Entities.Globals'Access /= Enclosing then
         GNATdoc.Entities.Globals.Task_Types.Insert (Entity);
      end if;

      Check_Undocumented (Entity);

      if not Decl.F_Definition.Is_Null then
         Process_Children (Decl.F_Definition.F_Public_Part, Entity, False);

         if GNATdoc.Options.Frontend_Options.Generate_Private then
            Process_Children (Decl.F_Definition.F_Private_Part, Entity, True);
         end if;
      end if;
   end Process_Task_Decl;

   ------------------------
   -- Resolve_Belongs_To --
   ------------------------

   procedure Resolve_Belongs_To
     (Enclosing : not null GNATdoc.Entities.Entity_Information_Access;
      Belongs   : out GNATdoc.Entities.Entity_Information_Access;
      Entity    : not null GNATdoc.Entities.Entity_Information_Access)
   is
      Template   : constant VSS.Strings.Templates.Virtual_String_Template :=
        "unknown type `{}` is specified by `@belongs-to` tag";
      Belongs_To : constant VSS.Strings.Virtual_String :=
        Entity.Documentation.Belongs_To;

   begin
      Belongs := null;

      if not Entity.Documentation.Has_Belongs_To then
         return;
      end if;

      for E of Enclosing.Tagged_Types loop
         if E.Name = Belongs_To then
            Belongs := E;

            return;
         end if;
      end loop;

      for E of Enclosing.Interface_Types loop
         if E.Name = Belongs_To then
            Belongs := E;

            return;
         end if;
      end loop;

      Entity.Messages.Append_Message
        (Entity.Location,
         Template.Format
           (VSS.Strings.Formatters.Strings.Image (Belongs_To)));
   end Resolve_Belongs_To;

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
           (VSS.Strings.To_Virtual_String (Node.F_Subp_Name.Text));

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

                        if Type_Decl_Node.As_Subtype_Indication.F_Name.Kind
                          = Ada_Attribute_Ref
                        then
                           Type_Name.Append (''');
                           Type_Name.Append
                             (VSS.Strings.To_Virtual_String
                                (Type_Decl_Node.As_Subtype_Indication.F_Name
                                 .As_Attribute_Ref.F_Attribute.Text));
                        end if;

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

   function Signature
     (Name : Defining_Name'Class) return GNATdoc.Entities.Entity_Signature is
   begin
      if Name.Unit = Name.P_Standard_Unit then
         return (others => <>);
      end if;

      return Result : GNATdoc.Entities.Entity_Signature :=
        (Image => To_Virtual_String (Name.P_Unique_Identifying_Name))
      do
         case Name.P_Basic_Decl.Kind is
            when Ada_Entry_Body
               | Ada_Expr_Function
               | Ada_Package_Body
               | Ada_Protected_Body
               | Ada_Subp_Body
               | Ada_Subp_Renaming_Decl
            =>
               Result.Image.Append ('$');

            when Ada_Generic_Subp_Instantiation =>
               Result.Image.Append (To_Virtual_String (Name.Full_Sloc_Image));
               --  ??? LAL: bug in P_Unique_Identifying_Name for generic
               --  subprogram instantiations

            when Ada_Abstract_Subp_Decl
               | Ada_Concrete_Formal_Subp_Decl
               | Ada_Entry_Decl
               | Ada_Exception_Decl
               | Ada_Generic_Package_Decl
               | Ada_Generic_Package_Instantiation
               | Ada_Generic_Subp_Decl
               | Ada_Null_Subp_Decl
               | Ada_Number_Decl
               | Ada_Object_Decl
               | Ada_Package_Renaming_Decl
               | Ada_Package_Decl
               | Ada_Protected_Type_Decl
               | Ada_Single_Protected_Decl
               | Ada_Single_Task_Type_Decl
               | Ada_Subp_Decl
               | Ada_Subtype_Decl
               | Ada_Task_Type_Decl
               | Ada_Type_Decl
            =>
               null;

            when others =>
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error,
                  Image (Name) & ": signature of "
                  & Image (Name.P_Basic_Decl)
                  & " => "
                  & VSS.Strings.Conversions.To_UTF_8_String (Result.Image));
         end case;
      end return;
   end Signature;

   -----------------------------
   -- Subprogram_Primary_View --
   -----------------------------

   function Subprogram_Primary_View
     (Node : Basic_Decl'Class) return Basic_Decl
   is
      Aux : Basic_Decl;

   begin
      case Node.Kind is
         when Ada_Subp_Decl | Ada_Abstract_Subp_Decl =>
            null;

         when Ada_Expr_Function
            | Ada_Null_Subp_Decl
            | Ada_Subp_Body
            | Ada_Subp_Renaming_Decl
         =>
            Aux := Node.As_Base_Subp_Body.P_Decl_Part;

         when others =>
            GNATdoc.Messages.Raise_Not_Implemented
              (Libadalang.Analysis.Image (Node) & " not supported");
      end case;

      return (if Aux.Is_Null then Node.As_Basic_Decl else Aux);
   end Subprogram_Primary_View;

end GNATdoc.Frontend;
