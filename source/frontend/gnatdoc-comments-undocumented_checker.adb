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

with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

package body GNATdoc.Comments.Undocumented_Checker is

   Entity_Not_Documented_Template :
     VSS.Strings.Templates.Virtual_String_Template :=
       "entity `{}` is not documented";

   Named_Component_Not_Documented_Template :
     VSS.Strings.Templates.Virtual_String_Template :=
       "{} `{}` is not documented";

   Unnamed_Component_Not_Documented_Template :
     VSS.Strings.Templates.Virtual_String_Template :=
       "{} is not documented";

   procedure Check
     (Location : GNATdoc.Source_Location;
      Sections : GNATdoc.Comments.Section_Vectors.Vector;
      Messages : in out GNATdoc.Messages.Message_Container);
   --  Check documentation for subsections.

   -----------
   -- Check --
   -----------

   procedure Check
     (Location : GNATdoc.Source_Location;
      Sections : GNATdoc.Comments.Section_Vectors.Vector;
      Messages : in out GNATdoc.Messages.Message_Container) is
   begin
      for Section of Sections loop
         if Section.Kind in Formal then
            pragma Assert (Section.Text.Is_Empty);
            pragma Assert
              (for some Subsection of Section.Sections =>
                 Subsection.Kind = Description);

            --  Look for documnetation section of generic formal parameter,
            --  and check that it is not empty.

            for Subsection of Section.Sections loop
               if Subsection.Kind in Description
                 and then Subsection.Text.Is_Empty
               then
                  declare
                     Text : VSS.Strings.Virtual_String;

                  begin
                     Text :=
                       Named_Component_Not_Documented_Template.Format
                         (VSS.Strings.Formatters.Strings.Image
                            ("generic formal"),
                          VSS.Strings.Formatters.Strings.Image (Section.Name));

                     Messages.Append_Message
                       (Location => Location,
                        Text     => Text);
                  end;
               end if;
            end loop;

            --  Check other subsections of generic formal parameter (parameters
            --  and return of formal subprograms).

            Check (Location, Section.Sections, Messages);

         elsif Section.Kind in Entity_Component
           and then Section.Text.Is_Empty
         then
            declare
               Text : VSS.Strings.Virtual_String;

            begin
               if Section.Kind = Returns then
                  Text :=
                    Unnamed_Component_Not_Documented_Template.Format
                      (VSS.Strings.Formatters.Strings.Image ("return value"));

               else
                  Text :=
                    Named_Component_Not_Documented_Template.Format
                      (VSS.Strings.Formatters.Strings.Image
                         (VSS.Strings.Virtual_String'
                            (case Section.Kind is
                             when Enumeration_Literal => "enumeration literal",
                             when Discriminant        => "discriminant",
                             when Component           => "component",
                             when Parameter           => "parameter",
                             when Raised_Exception    => "raised exception",
                             when others              => raise Program_Error)),
                       VSS.Strings.Formatters.Strings.Image (Section.Name));
               end if;

               Messages.Append_Message
                 (Location => Location,
                  Text     => Text);
            end;
         end if;
      end loop;
   end Check;

   ------------------------
   -- Check_Undocumented --
   ------------------------

   procedure Check_Undocumented
     (Location      : GNATdoc.Source_Location;
      Name          : VSS.Strings.Virtual_String;
      Documentation : GNATdoc.Comments.Structured_Comment;
      Messages      : in out GNATdoc.Messages.Message_Container) is
   begin
      --  Looking for description section and check that it is not empty.

      for Section of Documentation.Sections loop
         if Section.Kind in Description then
            if Section.Text.Is_Empty then
               Messages.Append_Message
                 (Location => Location,
                  Text     =>
                    Entity_Not_Documented_Template.Format
                      (VSS.Strings.Formatters.Strings.Image (Name)));
            end if;

            exit;
         end if;
      end loop;

      Check (Location, Documentation.Sections, Messages);
   end Check_Undocumented;

end GNATdoc.Comments.Undocumented_Checker;
