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

with Ada.Containers.Hashed_Maps;
with Ada.Containers.Ordered_Sets;

with VSS.Strings.Hash;

with GNATdoc.Comments;

package GNATdoc.Entities is

   type Entity_Kind is
     (Undefined,
      Ada_Tagged_Type,
      Ada_Interface_Type,
      Ada_Function,
      Ada_Procedure);

   type Entity_Information;

   type Entity_Information_Access is access all Entity_Information;

   function "<"
     (Left  : Entity_Information_Access;
      Right : Entity_Information_Access) return Boolean;

   package Entity_Information_Sets is
     new Ada.Containers.Ordered_Sets (Entity_Information_Access);

   package Entity_Information_Maps is
     new Ada.Containers.Hashed_Maps
       (VSS.Strings.Virtual_String,
        Entity_Information_Access,
        VSS.Strings.Hash,
        VSS.Strings."=");

   type Entity_Reference is record
      Qualified_Name : VSS.Strings.Virtual_String;
      Signature      : VSS.Strings.Virtual_String;
   end record;

   overriding function "="
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean;

   function "<"
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean;

   package Entity_Reference_Sets is
     new Ada.Containers.Ordered_Sets (Entity_Reference);

   type Entity_Information is record
      Location               : Source_Location;
      Kind                   : Entity_Kind := Undefined;
      Name                   : VSS.Strings.Virtual_String;
      Qualified_Name         : VSS.Strings.Virtual_String;
      Signature              : VSS.Strings.Virtual_String;
      Documentation          : aliased GNATdoc.Comments.Structured_Comment;

      Enclosing              : VSS.Strings.Virtual_String;
      --  Signature of the enclosing entity.
      Is_Private             : Boolean := False;
      --  Private entities are excluded from the documentartion.

      Is_Method              : Boolean := False;
      --  True means that this subprogram is a "method" of some tagged type,
      --  thus, it should be documented in "class" documentation; otherwise,
      --  it is documented in "unit" documentation.

      RST_Profile            : VSS.Strings.Virtual_String;
      --  Subprogram's profile in fortmat to use by RST backend

      Packages               : Entity_Information_Sets.Set;
      Subprograms            : aliased Entity_Information_Sets.Set;
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
      Variables              : aliased Entity_Information_Sets.Set;
      Exceptions             : aliased Entity_Information_Sets.Set;

      --  Access_Types      : EInfo_List.Vector;  +++
      --  Generic_Formals   : EInfo_List.Vector;  +++
      --  Interface_Types   : EInfo_List.Vector;  +++
      --  Methods           : EInfo_List.Vector;  ???
      --  Pkgs              : EInfo_List.Vector;  +++
      --  --  Ordinary and generic packages.
      --  Pkgs_Instances    : EInfo_List.Vector;  +++
      --  --  Generic packages instantiations.
      --  Record_Types      : EInfo_List.Vector;  +++
      --  Simple_Types      : EInfo_List.Vector;  +++
      --  Subprgs           : EInfo_List.Vector;  +++
      --  --  Ordinary subprograms.
      --  Subprgs_Instances : EInfo_List.Vector;  +++
      --  --  Generic subprograms instantiations.
      --  Tagged_Types      : EInfo_List.Vector;  +++
      --  Variables         : EInfo_List.Vector;  +++
      --  Tasks             : EInfo_List.Vector;  +++
      --  Protected_Objects : EInfo_List.Vector;  +++
      --  Entries           : EInfo_List.Vector;  +++

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

      Owner_Class               : Entity_Reference;
      --  Reference to the type that "declare" non dispatching subprogram.

      Non_Dispatching_Declared  : aliased Entity_Reference_Sets.Set;
      --  Non dispatching operations declared by the type, and can be called
      --  with prefixed notation.

      Non_Dispatching_Inherited : aliased Entity_Reference_Sets.Set;
      --  Non dispatching operations inherited by the type, and can be called
      --  with prefixed notation.
   end record;

   Globals   : aliased Entity_Information;
   --  Set of all compilation units (including packages, subprograms,
   --  renamings, generics and instantiations) and all nested packages
   --  and generic packages.

   To_Entity : Entity_Information_Maps.Map;
   --  Map to lookup entity's information by entity's signature.

   function All_Entities
     (Self : Entity_Information) return Entity_Information_Sets.Set;

end GNATdoc.Entities;
