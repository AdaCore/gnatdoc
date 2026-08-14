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

with Ada.Containers.Vectors;

with VSS.Strings;
with VSS.String_Vectors;

package GNATdoc.Comments.CM_Helpers is

   type Legacy_Doc_Block is record
      Name : VSS.Strings.Virtual_String;
      Line : VSS.Strings.Line_Offset;
      Text : VSS.String_Vectors.Virtual_String_Vector;
   end record;

   package Legacy_Doc_Block_Vectors is
     new Ada.Containers.Vectors (Positive, Legacy_Doc_Block);

   function Get_CM_Documentation
     (Documentation : Structured_Comment)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Return documentation serialized in the legacy cm backend format.

   function Has_Exclude_Tag_Mention
     (Documentation : Structured_Comment) return Boolean;
   --  Return True when documentation text mentions `@exclude` as prose.

   function Get_Legacy_Doc_Blocks
     (Documentation : Structured_Comment)
      return Legacy_Doc_Block_Vectors.Vector;
   --  Return legacy documentation blocks that were emitted as standalone
   --  records by the old cm backend.

end GNATdoc.Comments.CM_Helpers;