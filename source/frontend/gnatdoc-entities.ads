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

with Ada.Containers.Ordered_Sets;

with VSS.Strings;

with GNATdoc.Comments;

package GNATdoc.Entities is

   type Entity_Information;

   type Entity_Information_Access is access all Entity_Information;

   function "<"
     (Left  : Entity_Information_Access;
      Right : Entity_Information_Access) return Boolean;

   package Entity_Information_Sets is
     new Ada.Containers.Ordered_Sets (Entity_Information_Access);

   type Entity_Information is record
      Name           : VSS.Strings.Virtual_String;
      Qualified_Name : VSS.Strings.Virtual_String;
      Signature      : VSS.Strings.Virtual_String;
      Documentation  : GNATdoc.Comments.Structured_Comment;

      Packages       : Entity_Information_Sets.Set;
      Subprograms    : Entity_Information_Sets.Set;
      --  Generic_Packages
      --  Generic_Subprograms
      --  Package_Instantiations
      --  Subprogram_Instantiations

      Simple_Types   : Entity_Information_Sets.Set;
      Record_Types   : Entity_Information_Sets.Set;
      Subtypes       : Entity_Information_Sets.Set;
      Constants      : Entity_Information_Sets.Set;
      Variables      : Entity_Information_Sets.Set;

      --  Access_Types      : EInfo_List.Vector;
      --  CPP_Classes       : EInfo_List.Vector;
      --  CPP_Constructors  : EInfo_List.Vector;
      --  Generic_Formals   : EInfo_List.Vector;
      --  Interface_Types   : EInfo_List.Vector;
      --  Methods           : EInfo_List.Vector;
      --  Pkgs              : EInfo_List.Vector;
      --  --  Ordinary and generic packages.
      --  Pkgs_Instances    : EInfo_List.Vector;
      --  --  Generic packages instantiations.
      --  Record_Types      : EInfo_List.Vector;  +++
      --  Simple_Types      : EInfo_List.Vector;  +++
      --  Subprgs           : EInfo_List.Vector;  +++
      --  --  Ordinary subprograms.
      --  Subprgs_Instances : EInfo_List.Vector;
      --  --  Generic subprograms instantiations.
      --  Tagged_Types      : EInfo_List.Vector;
      --  Variables         : EInfo_List.Vector;  +++
      --  Tasks             : EInfo_List.Vector;
      --  Protected_Objects : EInfo_List.Vector;
      --  Entries           : EInfo_List.Vector;

   end record;

   Global_Entities : aliased Entity_Information;

   function All_Entities
     (Self : Entity_Information) return Entity_Information_Sets.Set;

end GNATdoc.Entities;
