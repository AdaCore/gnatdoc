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

with Ada.Streams;

with VSS.Stream_Element_Vectors.Conversions;

package body Streams is

   -----------
   -- Close --
   -----------

   procedure Close (Self : in out Output_Text_Stream'Class) is
   begin
      GNATCOLL.VFS.Close (Self.Writable);
   end Close;

   ----------
   -- Open --
   ----------

   procedure Open
     (Self : in out Output_Text_Stream'Class;
      File : GNATCOLL.VFS.Virtual_File) is
   begin
      Self.Encoder.Initialize ("utf-8");
      Self.Writable := File.Write_File;
   end Open;

   ---------
   -- Put --
   ---------

   overriding procedure Put
     (Self    : in out Output_Text_Stream;
      Item    : VSS.Characters.Virtual_Character;
      Success : in out Boolean)
   is
      Data : constant String :=
        VSS.Stream_Element_Vectors.Conversions.Unchecked_To_String
          (Self.Encoder.Encode (Item));

   begin
      GNATCOLL.VFS.Write (Self.Writable, Data);
   end Put;

end Streams;
