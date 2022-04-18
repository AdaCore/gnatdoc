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

package body GNATdoc.Comments.Helpers is

   use VSS.Strings;

   --------------------------------
   -- Get_Subprogram_Description --
   --------------------------------

   function Get_Subprogram_Description
     (Self       : Structured_Comment'Class;
      Terminator : VSS.Strings.Line_Terminator := VSS.Strings.LF)
      return VSS.Strings.Virtual_String
   is
      Text            : VSS.String_Vectors.Virtual_String_Vector;
      First_Parameter : Boolean := True;
      First_Exception : Boolean := True;

   begin
      if Self.Has_Documentation then
         for Section of Self.Sections loop
            if Section.Kind = Description then
               Text := Section.Text;
            end if;
         end loop;

         --  Append parameters

         for Section of Self.Sections loop
            if Section.Kind = Parameter then
               if First_Parameter then
                  Text.Append (Empty_Virtual_String);
                  First_Parameter := False;
               end if;

               Text.Append ("@param " & Section.Name);

               for L of Section.Text loop
                  Text.Append ("  " & L);
               end loop;
            end if;
         end loop;

         --  Append return

         for Section of Self.Sections loop
            if Section.Kind = Returns then
               Text.Append (Empty_Virtual_String);
               Text.Append ("@return");

               for L of Section.Text loop
                  Text.Append ("  " & L);
               end loop;
            end if;
         end loop;

         --  Append exceptions

         for Section of Self.Sections loop
            if Section.Kind = Raised_Exception then
               if First_Exception then
                  Text.Append (Empty_Virtual_String);
                  First_Exception := False;
               end if;

               Text.Append ("@exception " & Section.Name);

               for L of Section.Text loop
                  Text.Append ("  " & L);
               end loop;
            end if;
         end loop;
      end if;

      return Text.Join_Lines (Terminator, False);
   end Get_Subprogram_Description;

   ------------------------------------------
   -- Get_Subprogram_Parameter_Description --
   ------------------------------------------

   function Get_Subprogram_Parameter_Description
     (Self       : Structured_Comment'Class;
      Symbol     : VSS.Strings.Virtual_String;
      Terminator : VSS.Strings.Line_Terminator := VSS.Strings.LF)
      return VSS.Strings.Virtual_String
   is
      Text : VSS.String_Vectors.Virtual_String_Vector;

   begin
      for Section of Self.Sections loop
         if Section.Kind = Parameter and Section.Symbol = Symbol then
            Text := Section.Text;
         end if;
      end loop;

      return Text.Join_Lines (Terminator, False);
   end Get_Subprogram_Parameter_Description;

   ----------------------------
   -- Get_Subprogram_Snippet --
   ----------------------------

   function Get_Subprogram_Snippet
     (Self : Structured_Comment'Class)
      return VSS.String_Vectors.Virtual_String_Vector is
   begin
      for Section of Self.Sections loop
         if Section.Kind = Snippet and Section.Symbol = "ada" then
            return Section.Text;
         end if;
      end loop;

      return VSS.String_Vectors.Empty_Virtual_String_Vector;
   end Get_Subprogram_Snippet;

end GNATdoc.Comments.Helpers;
