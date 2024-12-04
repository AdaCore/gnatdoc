------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2023-2024, AdaCore                     --
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

with VSS.Strings;
with VSS.String_Vectors;

package GNATdoc.Comments.RST_Helpers is

   function Get_RST_Documentation
     (Indent        : VSS.Strings.Virtual_String;
      Documentation : Structured_Comment;
      Pass_Through  : Boolean;
      Code_Snippet  : Boolean)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Return description as RST text.
   --
   --  @param Indent
   --    String to be used for lines indentation in generated text.
   --  @param Documentation Structured comment to format as RST.
   --  @param Pass_Through
   --    When True only entry for entity, code snippet of the declaration and
   --    description is added to the generated text. Description of other
   --    components is expected to be present in the description.
   --  @param Code_Snippet
   --    When True code snippet is added to the documentation.

end GNATdoc.Comments.RST_Helpers;
