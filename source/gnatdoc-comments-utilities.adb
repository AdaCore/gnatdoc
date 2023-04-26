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

with VSS.Regular_Expressions;         use VSS.Regular_Expressions;
with VSS.Strings;                     use VSS.Strings;
with VSS.Strings.Conversions;         use VSS.Strings.Conversions;

with Langkit_Support.Symbols;
with Libadalang.Common;

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

   ---------------
   -- To_Symbol --
   ---------------

   function To_Symbol
     (Name : Libadalang.Analysis.Defining_Name'Class)
      return VSS.Strings.Virtual_String
   is
      use Langkit_Support.Text;
      use Libadalang.Common;

   begin
      return
        --  To_Virtual_String (Node.F_Name.P_Canonical_Text),
        VSS.Strings.Conversions.To_Virtual_String
          ((if Name.F_Name.Kind = Ada_Char_Literal
              then To_Unbounded_Text (Text (Name.Token_Start))
              else Name.F_Name.P_Canonical_Text));
      --  LAL: P_Canonical_Text do case conversion which makes lowercase and
      --  uppercase character literals undistingushable.
   end To_Symbol;

   ---------------
   -- To_Symbol --
   ---------------

   function To_Symbol
     (Name : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String
   is
      use Langkit_Support.Symbols;

   begin
      --  Compute symbol name. For character literals it is equal to name, for
      --  identifiers it is canonicalized name.

      return
        (if Name.Starts_With ("'")
           then Name
           else To_Virtual_String
                  (Fold_Case (To_Wide_Wide_String (Name)).Symbol));
   end To_Symbol;

end GNATdoc.Comments.Utilities;
