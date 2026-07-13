------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2023-2026, AdaCore                     --
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
with VSS.Strings.Formatters.Strings; use VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;          use VSS.Strings.Templates;

with GNATdoc.Backend.RST_Markup;

package body GNATdoc.Comments.RST_Helpers is

   use VSS.Characters.Latin;
   use VSS.Strings.Character_Iterators;
   use type VSS.Characters.Virtual_Character;
   use type VSS.Strings.Virtual_String;

   procedure Append_Indented_Lines
     (To     : in out VSS.String_Vectors.Virtual_String_Vector;
      Indent : VSS.Strings.Virtual_String;
      Text   : VSS.String_Vectors.Virtual_String_Vector);

   ---------------------------
   -- Append_Indented_Lines --
   ---------------------------

   procedure Append_Indented_Lines
     (To     : in out VSS.String_Vectors.Virtual_String_Vector;
      Indent : VSS.Strings.Virtual_String;
      Text   : VSS.String_Vectors.Virtual_String_Vector) is
   begin
      for Line of Text loop
         To.Append (Indent & Line);
      end loop;
   end Append_Indented_Lines;

   ---------------------------
   -- Get_RST_Documentation --
   ---------------------------

   function Get_RST_Documentation
     (Indent        : VSS.Strings.Virtual_String;
      Documentation : Structured_Comment;
      Pass_Through  : Boolean;
      Code_Snippet  : Boolean)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Text         : VSS.String_Vectors.Virtual_String_Vector;
      Add_New_Line : Boolean := False;

   begin
      --  Insert code block first

      for Section of Documentation.Sections loop
         if Code_Snippet
           and Section.Kind = Snippet
           and Section.Symbol = "ada"
         then
            Text.Append (Indent & ".. code-block:: ada");
            Text.Append (VSS.Strings.Empty_Virtual_String);

            for Line of Section.Text loop
               Text.Append (Indent & "   " & Line);
            end loop;

            Text.Append (VSS.Strings.Empty_Virtual_String);
            Text.Append (VSS.Strings.Empty_Virtual_String);

            exit;
         end if;
      end loop;

      --  Append components of type

      for Section of Documentation.Sections loop
         if Section.Kind in Component | Discriminant then
            declare
               Tag                : constant VSS.Strings.Virtual_String :=
                 (case Section.Kind is
                     when Component => "component",
                     when Discriminant => "discriminant",
                     when others => raise Program_Error);
               Component_Template : constant Virtual_String_Template :=
                 "{}:{} {} {}:";

            begin
               Text.Append
                 (Component_Template.Format
                    (Image (Indent),
                     Image (Tag),
                     Image (RST_Type_Image (Section.RST_Info)),
                     Image (Section.Name)));

               if Section.Text.Is_Empty then
                  --  Empty line is necessary to prevent error reported by
                  --  Sphynx

                  Text.Append (VSS.Strings.Empty_Virtual_String);

               else
                  Append_Indented_Lines
                    (Text,
                     Indent & "    ",
                     (if Pass_Through
                      then Section.Text
                      else GNATdoc.Backend.RST_Markup.Build_Markup
                        (Section.Text)));
               end if;

               Add_New_Line := True;
            end;
         end if;
      end loop;

      if Add_New_Line then
         Add_New_Line := False;
         Text.Append (VSS.Strings.Empty_Virtual_String);
      end if;

      --  Append description

      for Section of Documentation.Sections loop
         if Section.Kind = Description then
            if Pass_Through then
               for Line of Section.Text loop
                  Text.Append (Indent & Line);
               end loop;

            else
               Text.Append
                 (GNATdoc.Backend.RST_Markup.Build_Markup (Section.Text));
            end if;

            exit;
         end if;
      end loop;

      --  In pass-throuh mode documentation for parameters, return values, etc.
      --  is included in the description section.

      if not Pass_Through then
         --  Append parameters and return value

         for Section of Documentation.Sections loop
            if Section.Kind = Parameter then
               Text.Append (VSS.Strings.Empty_Virtual_String);
               Text.Append (Indent & ":parameter " & Section.Name & ":");

               Append_Indented_Lines
                 (Text,
                  Indent & "    ",
                  (if Pass_Through
                   then Section.Text
                   else GNATdoc.Backend.RST_Markup.Build_Markup
                     (Section.Text)));

               Text.Append (VSS.Strings.Empty_Virtual_String);
            end if;
         end loop;

         for Section of Documentation.Sections loop
            if Section.Kind = Returns then
               Text.Append (VSS.Strings.Empty_Virtual_String);
               Text.Append (Indent & ":returns:");

               Append_Indented_Lines
                 (Text,
                  Indent & "    ",
                  (if Pass_Through
                   then Section.Text
                   else GNATdoc.Backend.RST_Markup.Build_Markup
                     (Section.Text)));

               Text.Append (VSS.Strings.Empty_Virtual_String);

               exit;
            end if;
         end loop;

         for Section of Documentation.Sections loop
            if Section.Kind = Raised_Exception then
               Text.Append (VSS.Strings.Empty_Virtual_String);
               Text.Append (Indent & ":exception " & Section.Name & ":");

               Append_Indented_Lines
                 (Text,
                  Indent & "    ",
                  (if Pass_Through
                   then Section.Text
                   else GNATdoc.Backend.RST_Markup.Build_Markup
                     (Section.Text)));

               Text.Append (VSS.Strings.Empty_Virtual_String);

               exit;
            end if;
         end loop;
      end if;

      return Text;
   end Get_RST_Documentation;

   --------------------
   -- RST_Type_Image --
   --------------------

   function RST_Type_Image
     (Type_Name : VSS.Strings.Virtual_String)
      return VSS.Strings.Virtual_String
   is
      Iterator : Character_Iterator := Type_Name.At_First_Character;

   begin
      while Iterator.Forward loop
         if Iterator.Element = Space then
            return "``" & Type_Name & "``";
         end if;
      end loop;

      return Type_Name;
   end RST_Type_Image;

end GNATdoc.Comments.RST_Helpers;
