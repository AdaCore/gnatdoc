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

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Ordered_Sets;

with GNATdoc.Comments;
with GNATdoc.Messages;

package GNATdoc.Entities is

   type Entity_Kind is
     (Undefined,
      Ada_Tagged_Type,
      Ada_Interface_Type,
      Ada_Other_Type,
      Ada_Named_Number,
      Ada_Object,
      Ada_Exception,
      Ada_Function,
      Ada_Procedure,
      Ada_Formal,
      Ada_Generic_Package_Instantiation,
      Ada_Generic_Subprogram_Instantiation);

   type Entity_Signature is record
      Image : VSS.Strings.Virtual_String;
   end record;

   function Hash (Self : Entity_Signature) return Ada.Containers.Hash_Type;

   type Entity_Information;

   type Entity_Information_Access is access all Entity_Information;

   function "<"
     (Left  : Entity_Information_Access;
      Right : Entity_Information_Access) return Boolean;

   function Is_In_Declaration_Order
     (Left  : Entity_Information_Access;
      Right : Entity_Information_Access) return Boolean;

   package Entity_Information_Sets is
     new Ada.Containers.Ordered_Sets (Entity_Information_Access);

   package Entity_Information_Declaration_Order_Sets is
     new Ada.Containers.Ordered_Sets
       (Element_Type => Entity_Information_Access,
        "<"          => Is_In_Declaration_Order,
        "="          => "=");

   package Entity_Information_Maps is
     new Ada.Containers.Hashed_Maps
       (Key_Type        => Entity_Signature,
        Element_Type    => Entity_Information_Access,
        Hash            => Hash,
        Equivalent_Keys => "=");

   type Entity_Reference is record
      Qualified_Name : VSS.Strings.Virtual_String;
      Signature      : Entity_Signature;
   end record;

   function Is_Undefined (Self : Entity_Reference) return Boolean;
   --  Returns True when given reference doesn't point to any entity (its
   --  signature is empty).

   overriding function "="
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean;

   function "<"
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean;

   function Is_In_Declaration_Order
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean;

   package Entity_Reference_Sets is
     new Ada.Containers.Ordered_Sets (Entity_Reference);

   package Entity_Reference_Declaration_Order_Sets is
     new Ada.Containers.Ordered_Sets
       (Element_Type => Entity_Reference,
        "<"          => Is_In_Declaration_Order,
        "="          => "=");

   type Entity_Information is tagged limited record
      Location               : Source_Location;
      Kind                   : Entity_Kind := Undefined;
      Is_Specification       : Boolean     := True;
      Name                   : VSS.Strings.Virtual_String;
      Qualified_Name         : VSS.Strings.Virtual_String;
      Signature              : Entity_Signature;
      Documentation          : aliased GNATdoc.Comments.Structured_Comment;
      Messages               : GNATdoc.Messages.Message_Container;

      Enclosing              : Entity_Signature;
      --  Structural enclosing entity (package/task/protected object).
      Belongs                : Entity_Reference;
      --  Reference to the entity it belongs. It is set to refer to type when
      --  entity `@belongs-to` explicitly (for constants/subprogram), or then
      --  subprogram:
      --    * can be called with prefix notation
      --    * is a primitive operations of the tagged type

      Contain_Entities       : Entity_Information_Declaration_Order_Sets.Set;
      --  All nested entities (structural view, in declaration order)
      Belong_Entities        : Entity_Reference_Declaration_Order_Sets.Set;
      --  All belong entities (belongs view, in declaration order)

      Is_Private             : Boolean := False;
      --  Private entities are excluded from the documentartion.

      Is_Method              : Boolean := False;
      --  True means that this subprogram is a "method" of some tagged type,
      --  thus, it should be documented in "class" documentation; otherwise,
      --  it is documented in "unit" documentation.

      RST_Profile            : VSS.Strings.Virtual_String;
      --  Subprogram's profile in fortmat to use by RST backend
      RSTPT_Objtype          : VSS.Strings.Virtual_String;
      --  Name of the type of the object
      RSTPT_Defval           : VSS.Strings.Virtual_String;
      --  Default value of the object
      RSTPT_Instpkg          : VSS.Strings.Virtual_String;
      --  Name of instantiated package

      Packages               : Entity_Information_Sets.Set;
      Contain_Subprograms    : aliased Entity_Reference_Sets.Set;
      --  All subprograms declared in the entity (package)
      Belong_Subprograms     : aliased Entity_Reference_Sets.Set;
      --  Subprograms that belongs to the entity (to interface/tagged type,
      --  otherwise to the package)
      Entries                : aliased Entity_Information_Sets.Set;
      Generic_Instantiations : aliased Entity_Information_Sets.Set;
      --  Generic_Packages
      --  Generic_Subprograms
      --  Package_Instantiations
      --  Subprogram_Instantiations
      Package_Renamings      : Entity_Information_Sets.Set;
      --  Renamings of the packages. Renamings of the subprograms is in
      --  the Subprograms field.

      Formals                : aliased Entity_Information_Sets.Set;
      Simple_Types           : aliased Entity_Information_Sets.Set;
      Array_Types            : aliased Entity_Information_Sets.Set;
      Record_Types           : aliased Entity_Information_Sets.Set;
      Interface_Types        : aliased Entity_Information_Sets.Set;
      Tagged_Types           : aliased Entity_Information_Sets.Set;
      Task_Types             : aliased Entity_Information_Sets.Set;
      Protected_Types        : aliased Entity_Information_Sets.Set;
      Access_Types           : aliased Entity_Information_Sets.Set;
      Subtypes               : aliased Entity_Information_Sets.Set;
      Constants              : aliased Entity_Information_Sets.Set;
      Belongs_Constants      : aliased Entity_Reference_Sets.Set;
      --  Constants that belongs to the entity (to interface/tagged type,
      --  otherwise to the package)
      Variables              : aliased Entity_Information_Sets.Set;
      Exceptions             : aliased Entity_Information_Sets.Set;

      Parent_Type            : Entity_Reference;
      --  Reference to parent tagged type.

      Progenitor_Types       : aliased Entity_Reference_Sets.Set;
      --  References to progenitor types.

      Derived_Types          : aliased Entity_Reference_Sets.Set;
      --  References to known derived types.

      All_Parent_Types       : aliased Entity_Reference_Sets.Set;
      All_Progenitor_Types   : aliased Entity_Reference_Sets.Set;
      All_Derived_Types      : aliased Entity_Reference_Sets.Set;
      --  References to all known direct or indirect parent and derived types.

      Dispatching_Declared   : aliased Entity_Reference_Sets.Set;
      --  Displatching operations declared by the type.

      Dispatching_Overrided  : aliased Entity_Reference_Sets.Set;
      --  Dispatching operations overrided by the type.

      Dispatching_Inherited  : aliased Entity_Reference_Sets.Set;
      --  Dispatching operations inherited by the type.

      Prefix_Callable_Declared  : aliased Entity_Reference_Sets.Set;
      --  Prefix callable subprograms declared by the type.

      Prefix_Callable_Inherited : aliased Entity_Reference_Sets.Set;
      --  Non dispatching operations inherited by the type.
   end record;

   Globals   : aliased Entity_Information;
   --  Set of all compilation units (including packages, subprograms,
   --  renamings, generics and instantiations) and all nested packages
   --  and generic packages.

   To_Entity : Entity_Information_Maps.Map;
   --  Map to lookup entity's information by entity's signature.

   function Reference
     (Self : Entity_Information'Class) return Entity_Reference;
   --  Reference of entity

end GNATdoc.Entities;
