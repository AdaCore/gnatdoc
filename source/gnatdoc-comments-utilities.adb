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

with VSS.Regular_Expressions;         use VSS.Regular_Expressions;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Conversions;         use VSS.Strings.Conversions;

package body GNATdoc.Comments.Utilities is

   -------------------------------
   -- Append_Documentation_Line --
   -------------------------------

   procedure Append_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression)
   is
      L : constant Virtual_String := To_Virtual_String (Line);
      M : Regular_Expression_Match;

   begin
      if Pattern.Is_Valid then
         M := Pattern.Match (L);

         if M.Has_Match then
            Text.Append (L);
         end if;

      else
         Text.Append (L);
      end if;
   end Append_Documentation_Line;

end GNATdoc.Comments.Utilities;
