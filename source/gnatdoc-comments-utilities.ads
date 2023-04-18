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

--  Utilities subprograms to share code between several packages.

with Langkit_Support.Text;
with Libadalang.Analysis;

with VSS.Regular_Expressions;

private package GNATdoc.Comments.Utilities is

   procedure Append_Documentation_Line
     (Text    : in out VSS.String_Vectors.Virtual_String_Vector;
      Line    : Langkit_Support.Text.Text_Type;
      Pattern : VSS.Regular_Expressions.Regular_Expression);
   --  Append given Line to the Text when Pattern is valid and Line match to
   --  Pattern. Always append Line when Pattern is invalid.

   function To_Symbol
     (Name : Libadalang.Analysis.Defining_Name'Class)
      return VSS.Strings.Virtual_String;
   --  Returns symbol of the defining name for internal use.

   function To_Symbol
     (Name : VSS.Strings.Virtual_String) return VSS.Strings.Virtual_String;
   --  Returns symbol of the name for internal use.

end GNATdoc.Comments.Utilities;
