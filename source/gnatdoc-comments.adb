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

with Ada.Unchecked_Deallocation;

package body GNATdoc.Comments is

   procedure Free is
     new Ada.Unchecked_Deallocation (Section'Class, Section_Access);

   -----------
   -- Clone --
   -----------

   function Clone
     (Section : not null Section_Access) return not null Section_Access is
   begin
      return
        new GNATdoc.Comments.Section'
             (Kind             => Section.Kind,
              Name             => Section.Name,
              Symbol           => Section.Symbol,
              Text             => Section.Text,
              Exact_Start_Line => 0,
              Exact_End_Line   => 0,
              Group_Start_Line => 0,
              Group_End_Line   => 0,
              Sections         => Clone (Section.Sections));
   end Clone;

   -----------
   -- Clone --
   -----------

   function Clone
     (Sections : Section_Vectors.Vector) return Section_Vectors.Vector is
   begin
      return Result : Section_Vectors.Vector do
         for Section of Sections loop
            Result.Append (Clone (Section));
         end loop;
      end return;
   end Clone;

   --------------
   -- Finalize --
   --------------

   not overriding procedure Finalize (Self : in out Section) is
   begin
      for Section of Self.Sections loop
         Finalize (Section.all);
         Free (Section);
      end loop;

      Self.Sections.Clear;
   end Finalize;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (Self : in out Structured_Comment) is
   begin
      for Section of Self.Sections loop
         Finalize (Section.all);
         Free (Section);
      end loop;

      Self.Sections.Clear;
   end Finalize;

   ----------
   -- Free --
   ----------

   procedure Free (Item : in out Structured_Comment_Access) is
      procedure Free is
        new Ada.Unchecked_Deallocation
          (Structured_Comment'Class, Structured_Comment_Access);

   begin
      if Item /= null then
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
         if Section.Kind in Description | Component
           and then not Section.Text.Is_Empty
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Documentation;

   ----------------
   -- Is_Private --
   ----------------

   function Is_Private (Self : Structured_Comment'Class) return Boolean is
   begin
      return Self.Is_Private;
   end Is_Private;

end GNATdoc.Comments;
