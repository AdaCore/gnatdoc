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

with Ada.Wide_Wide_Text_IO;   use Ada.Wide_Wide_Text_IO;

with VSS.Strings.Conversions; use VSS.Strings.Conversions;

with Langkit_Support.Slocs;   use Langkit_Support.Slocs;

package body GNATdoc.Comments.Debug is

   procedure Dump
     (Sections : Section_Vectors.Vector;
      Indent   : Wide_Wide_String);

   ----------
   -- Dump --
   ----------

   procedure Dump (Comment : Structured_Comment'Class) is
   begin
      Dump (Comment.Sections, "");
   end Dump;

   ----------
   -- Dump --
   ----------

   procedure Dump
     (Sections : Section_Vectors.Vector;
      Indent   : Wide_Wide_String) is
   begin
      for Section of Sections loop
         Put_Line
           (Indent
            & "\/ "
            & Section_Kind'Wide_Wide_Image (Section.Kind)
            & " "
            & To_Wide_Wide_String (Section.Symbol)
            & " ("
            & To_Wide_Wide_String (Section.Name)
            & ") "
            & Line_Number'Wide_Wide_Image (Section.Exact_Start_Line)
            & Line_Number'Wide_Wide_Image (Section.Exact_End_Line)
            & Line_Number'Wide_Wide_Image (Section.Group_Start_Line)
            & Line_Number'Wide_Wide_Image (Section.Group_End_Line));

         for Line of Section.Text loop
            Put_Line (To_Wide_Wide_String (Line));
         end loop;

         Dump (Section.Sections, Indent & "  ");
      end loop;
   end Dump;

end GNATdoc.Comments.Debug;
