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
      Indent   : Wide_Wide_String;
      Text     : in out VSS.String_Vectors.Virtual_String_Vector);

   ----------
   -- Dump --
   ----------

   procedure Dump (Comment : Structured_Comment'Class) is
      Text : VSS.String_Vectors.Virtual_String_Vector;

   begin
      Dump (Comment.Sections, "", Text);

      for Line of Text loop
         Put_Line (To_Wide_Wide_String (Line));
      end loop;
   end Dump;

   ----------
   -- Dump --
   ----------

   procedure Dump
     (Sections : Section_Vectors.Vector;
      Indent   : Wide_Wide_String;
      Text     : in out VSS.String_Vectors.Virtual_String_Vector) is
   begin
      for Section of Sections loop
         Text.Append
           (VSS.Strings.To_Virtual_String
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
               & Line_Number'Wide_Wide_Image (Section.Group_End_Line)));

         for Line of Section.Text loop
            Text.Append (Line);
         end loop;

         Dump (Section.Sections, Indent & "  ", Text);
      end loop;
   end Dump;

   ----------
   -- Dump --
   ----------

   function Dump (Comment : Structured_Comment'Class) return String is
      Text : VSS.String_Vectors.Virtual_String_Vector;

   begin
      Dump (Comment.Sections, "", Text);

      return To_UTF_8_String (Text.Join_Lines (VSS.Strings.LF));
   end Dump;

end GNATdoc.Comments.Debug;
