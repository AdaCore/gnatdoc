------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2023, AdaCore                        --
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

package body GNATdoc.Comments.RST_Helpers is

   ---------------------------
   -- Get_RST_Documentation --
   ---------------------------

   function Get_RST_Documentation
     (Indent        : VSS.Strings.Virtual_String;
      Documentation : Structured_Comment)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      use type VSS.Strings.Virtual_String;

      Text : VSS.String_Vectors.Virtual_String_Vector;

   begin
      --  Insert code block first

      for Section of Documentation.Sections loop
         if Section.Kind = Snippet and Section.Symbol = "ada" then
            Text.Append (Indent & ".. code-block:: ada");
            Text.Append (VSS.Strings.Empty_Virtual_String);

            for Line of Section.Text loop
               Text.Append (Indent & "   " & Line);
            end loop;

            Text.Append (VSS.Strings.Empty_Virtual_String);

            exit;
         end if;
      end loop;

      --  Append description

      for Section of Documentation.Sections loop
         if Section.Kind = Description then
            for Line of Section.Text loop
               Text.Append (Indent & Line);
            end loop;

            exit;
         end if;
      end loop;

      --  Append parameters and return value

      for Section of Documentation.Sections loop
         if Section.Kind = Parameter then
            Text.Append (VSS.Strings.Empty_Virtual_String);
            Text.Append (Indent & ":parameter " & Section.Name & ":");

            for Line of Section.Text loop
               Text.Append (Indent & "    " & Line);
            end loop;

            Text.Append (VSS.Strings.Empty_Virtual_String);
         end if;
      end loop;

      for Section of Documentation.Sections loop
         if Section.Kind = Returns then
            Text.Append (VSS.Strings.Empty_Virtual_String);
            Text.Append (Indent & ":returnvalue:");

            for Line of Section.Text loop
               Text.Append (Indent & "    " & Line);
            end loop;

            Text.Append (VSS.Strings.Empty_Virtual_String);

            exit;
         end if;
      end loop;

      return Text;
   end Get_RST_Documentation;

end GNATdoc.Comments.RST_Helpers;
