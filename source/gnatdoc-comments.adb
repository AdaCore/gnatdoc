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

with Ada.Unchecked_Deallocation;

package body GNATdoc.Comments is

   ----------
   -- Free --
   ----------

   procedure Free (Item : in out Structured_Comment_Access) is

      procedure Free is
        new Ada.Unchecked_Deallocation (Section'Class, Section_Access);
      procedure Free is
        new Ada.Unchecked_Deallocation
          (Structured_Comment'Class, Structured_Comment_Access);

   begin
      if Item /= null then
         for Section of Item.Sections loop
            Free (Section);
         end loop;

         Free (Item);
      end if;
   end Free;

   -----------------------
   -- Has_Documentation --
   -----------------------

   function Has_Documentation
     (Self : Structured_Comment'Class) return Boolean is
   begin
      for Section of Self.Sections loop
         if Section.Kind
              in Description | Parameter | Returns | Raised_Exception | Member
           and then not Section.Text.Is_Empty
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Documentation;

end GNATdoc.Comments;
