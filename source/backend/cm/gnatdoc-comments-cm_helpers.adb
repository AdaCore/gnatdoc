------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2026, AdaCore                          --
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

package body GNATdoc.Comments.CM_Helpers is

   use VSS.Strings;
   use VSS.String_Vectors;

   --------------------------
   -- Get_CM_Documentation --
   --------------------------

   function Get_CM_Documentation
     (Documentation : Structured_Comment)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Text         : VSS.String_Vectors.Virtual_String_Vector;
      First_Entity : Boolean := True;

      procedure Append_Block
        (Tag          : VSS.Strings.Virtual_String;
         Name         : VSS.Strings.Virtual_String;
         Lines        : VSS.String_Vectors.Virtual_String_Vector;
         Always_Emit  : Boolean := False);

      procedure Append_Block
        (Tag          : VSS.Strings.Virtual_String;
         Name         : VSS.Strings.Virtual_String;
         Lines        : VSS.String_Vectors.Virtual_String_Vector;
         Always_Emit  : Boolean := False) is
      begin
         if not Always_Emit and then Lines.Is_Empty then
            return;
         end if;

         if not First_Entity and then not Lines.Is_Empty then
            Text.Append (Empty_Virtual_String);
         end if;

         First_Entity := False;

         if Name.Is_Empty then
            Text.Append (Tag);

         else
            Text.Append (Tag & " " & Name);
         end if;

         for Line of Lines loop
            Text.Append ("  " & Line);
         end loop;
      end Append_Block;

   begin
      for Section of Documentation.Sections loop
         if Section.Kind = Description then
            for Line of Section.Text loop
               Text.Append ("  " & Line);
            end loop;
         end if;
      end loop;

      First_Entity := Text.Is_Empty;

      for Section of Documentation.Sections loop
         case Section.Kind is
            when Enumeration_Literal =>
               Append_Block ("@value", Section.Name, Section.Text, True);

            when Discriminant | Component =>
               Append_Block ("@field", Section.Name, Section.Text, True);

            when Parameter =>
               Append_Block ("@param", Section.Name, Section.Text);

            when Returns =>
               Append_Block ("@return", Empty_Virtual_String, Section.Text);

            when Raised_Exception =>
               Append_Block ("@exception", Section.Name, Section.Text);

            when Formal =>
               Append_Block ("@param", Section.Name, Section.Text);

            when others =>
               null;
         end case;
      end loop;

      return Text;
   end Get_CM_Documentation;

   -----------------------------
   -- Has_Exclude_Tag_Mention --
   -----------------------------

   function Has_Exclude_Tag_Mention
     (Documentation : Structured_Comment)
      return Boolean
   is
      Pattern : constant VSS.Strings.Virtual_String := "`@exclude` tag";

   begin
      if not Documentation.Has_Exclude then
         return False;
      end if;

      for Section of Documentation.Sections loop
         for Line of Section.Text loop
            if Line.Ends_With (Pattern) then
               return True;
            end if;
         end loop;
      end loop;

      return False;
   end Has_Exclude_Tag_Mention;

   ---------------------------
   -- Get_Legacy_Doc_Blocks --
   ---------------------------

   function Get_Legacy_Doc_Blocks
     (Documentation : Structured_Comment)
      return Legacy_Doc_Block_Vectors.Vector
   is
      Result                     : Legacy_Doc_Block_Vectors.Vector;
      Enum_With_Text_Count       : Natural := 0;
      Last_Enum_With_Text_Symbol : VSS.Strings.Virtual_String;

   begin
      for Section of Documentation.Sections loop
         if Section.Kind = Enumeration_Literal
           and then not Section.Text.Is_Empty
         then
            Enum_With_Text_Count := Enum_With_Text_Count + 1;
            Last_Enum_With_Text_Symbol := Section.Symbol;
         end if;
      end loop;

      for Section of Documentation.Sections loop
         if Section.Kind = Enumeration_Literal
           and then not Section.Text.Is_Empty
           and then
             (Enum_With_Text_Count = 1
              or else Section.Symbol /= Last_Enum_With_Text_Symbol)
         then
            Result.Append
              (Legacy_Doc_Block'
                 (Name => Section.Name,
                  Line =>
                    VSS.Strings.Line_Offset
                      (Section.Exact_Start_Line),
                  Text => Section.Text));
         end if;
      end loop;

      return Result;
   end Get_Legacy_Doc_Blocks;

end GNATdoc.Comments.CM_Helpers;