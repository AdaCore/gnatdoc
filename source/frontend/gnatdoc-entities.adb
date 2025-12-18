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

with VSS.Strings.Hash;

package body GNATdoc.Entities is

   ---------
   -- "<" --
   ---------

   function "<"
     (Left  : Entity_Information_Access;
      Right : Entity_Information_Access) return Boolean
   is
      use type VSS.Strings.Virtual_String;

   begin
      return Left.Signature.Image < Right.Signature.Image;
   end "<";

   ---------
   -- "<" --
   ---------

   function "<"
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean
   is
      use type VSS.Strings.Virtual_String;

   begin
      return Left.Signature.Image < Right.Signature.Image;
   end "<";

   ---------
   -- "=" --
   ---------

   overriding function "="
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean is
   begin
      return Left.Signature = Right.Signature;
   end "=";

   ----------
   -- Hash --
   ----------

   function Hash (Self : Entity_Signature) return Ada.Containers.Hash_Type is
   begin
      return VSS.Strings.Hash (Self.Image);
   end Hash;

   -----------------------------
   -- Is_In_Declaration_Order --
   -----------------------------

   function Is_In_Declaration_Order
     (Left  : Entity_Information_Access;
      Right : Entity_Information_Access) return Boolean
   is
      use type VSS.Strings.Character_Count;
      use type VSS.Strings.Line_Count;
      use type VSS.Strings.Virtual_String;

   begin
      if Left.Location.File < Right.Location.File then
         return True;

      elsif Left.Location.File = Right.Location.File
        and Left.Location.Line < Right.Location.Line
      then
         return True;

      elsif Left.Location.File = Right.Location.File
        and Left.Location.Line < Right.Location.Line
        and Left.Location.Column < Right.Location.Column
      then
         return True;

      else
         return False;
      end if;
   end Is_In_Declaration_Order;

   -----------------------------
   -- Is_In_Declaration_Order --
   -----------------------------

   function Is_In_Declaration_Order
     (Left  : Entity_Reference;
      Right : Entity_Reference) return Boolean is
   begin
      return
        Is_In_Declaration_Order
          (To_Entity (Left.Signature), To_Entity (Right.Signature));
   end Is_In_Declaration_Order;

   ------------------
   -- Is_Undefined --
   ------------------

   function Is_Undefined (Self : Entity_Reference) return Boolean is
   begin
      return Self.Signature.Image.Is_Empty;
   end Is_Undefined;

   ---------------
   -- Reference --
   ---------------

   function Reference
     (Self : Entity_Information'Class) return Entity_Reference is
   begin
      return
        (Qualified_Name => Self.Qualified_Name,
         Signature      => Self.Signature);
   end Reference;

end GNATdoc.Entities;
