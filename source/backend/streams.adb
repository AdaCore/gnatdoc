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

with VSS.Characters.Latin;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;

package body Streams is

   -----------
   -- Close --
   -----------

   procedure Close (Self : in out Output_Text_Stream'Class) is
   begin
      VSS.Text_Streams.File_Output.File_Output_Text_Stream
        (Self).Close;
   end Close;

   --------------
   -- New_Line --
   --------------

   procedure New_Line
     (Self    : in out Output_Text_Stream'Class;
      Success : in out Boolean) is
   begin
      Self.Put (VSS.Characters.Latin.Line_Feed, Success);
   end New_Line;

   ----------
   -- Open --
   ----------

   procedure Open
     (Self : in out Output_Text_Stream'Class;
      File : GNATCOLL.VFS.Virtual_File) is
   begin
      Self.Create
        (VSS.Strings.Conversions.To_Virtual_String (File.Display_Full_Name),
         "utf-8");
   end Open;

   ---------
   -- Put --
   ---------

   procedure Put
     (Self    : in out Output_Text_Stream'Class;
      Item    : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean)
   is
      Iterator : VSS.Strings.Character_Iterators.Character_Iterator :=
        Item.Before_First_Character;

   begin
      while Iterator.Forward loop
         exit when not Success;

         Self.Put (Iterator.Element, Success);
      end loop;
   end Put;

   ---------------
   -- Put_Lines --
   ---------------

   procedure Put_Lines
     (Self    : in out Output_Text_Stream'Class;
      Item    : VSS.String_Vectors.Virtual_String_Vector;
      Success : in out Boolean) is
   begin
      for Line of Item loop
         Self.Put (Line, Success);
         Self.New_Line (Success);
      end loop;
   end Put_Lines;

end Streams;
