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
      return Left.Signature < Right.Signature;
   end "<";

   ------------------
   -- All_Entities --
   ------------------

   function All_Entities
     (Self : Entity_Information) return Entity_Information_Sets.Set is
   begin
      return Result : Entity_Information_Sets.Set do
         Result.Union (Self.Packages);
         Result.Union (Self.Subprograms);
      end return;
   end All_Entities;

end GNATdoc.Entities;
