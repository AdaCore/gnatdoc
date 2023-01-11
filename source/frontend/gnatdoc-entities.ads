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

   type Entity_Location is record
      File   : VSS.Strings.Virtual_String;
      Line   : VSS.Strings.Line_Count      := 0;
      Column : VSS.Strings.Character_Count := 0;
   end record;

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

   type Entity_Information is record
      Location               : Entity_Location;
      Name                   : VSS.Strings.Virtual_String;
      Qualified_Name         : VSS.Strings.Virtual_String;
      Signature              : VSS.Strings.Virtual_String;
      Documentation          : aliased GNATdoc.Comments.Structured_Comment;

      Enclosing              : VSS.Strings.Virtual_String;
      --  Signature of the enclosing entity.
      Is_Private             : Boolean := False;
      --  Private entities are excluded from the documentartion.

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
      --  Generic_Formals   : EInfo_List.Vector;
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
