------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
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

with VSS.IRIs;
with VSS.XML.Attributes.Containers;

with GNATdoc.Backend.XML_Namespaces;

package body GNATdoc.Comments.XML_Helpers is

   use GNATdoc.Backend.XML_Namespaces;

   Description_Tag      : constant VSS.Strings.Virtual_String := "description";
   Formal_Tag           : constant VSS.Strings.Virtual_String := "formal";
   Enumeration_Literal_Tag : constant VSS.Strings.Virtual_String :=
     "enumeration-literal";
   Component_Tag        : constant VSS.Strings.Virtual_String := "component";
   Parameter_Tag        : constant VSS.Strings.Virtual_String := "parameter";
   Return_Tag           : constant VSS.Strings.Virtual_String := "return";
   Raised_Exception_Tag : constant VSS.Strings.Virtual_String :=
     "raised-exception";

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Comment : Structured_Comment;
      Writer  : in out VSS.XML.Writers.XML_Writer'Class;
      Success : in out Boolean)
   is
      Attributes : VSS.XML.Attributes.Containers.Attributes;
      Element    : VSS.Strings.Virtual_String;

   begin
      Attributes.Clear;
      Writer.Start_Element
        (GNATdoc_Namespace, "documentation", Attributes, Success);

      for Section of Comment.Sections loop
         if Section.Kind = Description
           and then not Section.Text.Is_Empty
         then
            Attributes.Clear;
            Writer.Start_Element
              (GNATdoc_Namespace, Description_Tag, Attributes, Success);
            Writer.Characters
              (Section.Text.Join_Lines (VSS.Strings.LF, False), Success);
            Writer.End_Element
              (GNATdoc_Namespace, Description_Tag, Success);
         end if;
      end loop;

      for Section of Comment.Sections loop
         if Section.Kind in Component then
            case Section.Kind is
               when Formal =>
                  Element := Formal_Tag;

               when Enumeration_Literal =>
                  Element := Enumeration_Literal_Tag;

               when Field =>
                  Element := Component_Tag;

               when Parameter =>
                  Element := Parameter_Tag;

               when Returns =>
                  Element := Return_Tag;

               when Raised_Exception =>
                  Element := Raised_Exception_Tag;

               when others =>
                  --  Should never happened

                  raise Program_Error with "unexpected kind of section";
            end case;

            Attributes.Clear;

            if Section.Kind /= Returns then
               Attributes.Insert
                 (VSS.IRIs.Empty_IRI, "name", Section.Name);
            end if;

            Writer.Start_Element
              (GNATdoc_Namespace, Element, Attributes, Success);

            if not Section.Text.Is_Empty then
               Attributes.Clear;
               Writer.Start_Element
                 (GNATdoc_Namespace, Description_Tag, Attributes, Success);
               Writer.Characters
                 (Section.Text.Join_Lines (VSS.Strings.LF, False), Success);
               Writer.End_Element
                 (GNATdoc_Namespace, Description_Tag, Success);
            end if;

            Writer.End_Element
              (GNATdoc_Namespace, Element, Success);
         end if;
      end loop;

      Writer.End_Element (GNATdoc_Namespace, "documentation", Success);
   end Generate;

end GNATdoc.Comments.XML_Helpers;
