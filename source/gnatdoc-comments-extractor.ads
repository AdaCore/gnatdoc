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

with Libadalang.Analysis;
with Libadalang.Common;

package GNATdoc.Comments.Extractor is

   use all type Libadalang.Common.Ada_Node_Kind_Type;

   type Documentation_Style is
     (GNAT,      --  Advanced GNAT style of the documentation comments
      Leading);  --  Simple leading style of the documentation comments

   type Extractor_Options is record
      Style    : Documentation_Style := GNAT;
      --  Style of the documentation comments.

      Fallback : Boolean             := False;
      --  Control wheather to attempt to extract documentation using simple
      --  "opposite" style (leading comments for GNAT style and trailing
      --  comments for Leading style).
      --
      --  This option is intended to be used by IDE.
   end record;

   function Extract
     (Node    : Libadalang.Analysis.Basic_Decl'Class;
      Options : Extractor_Options) return not null Structured_Comment_Access
     with Pre => Node.Kind in Ada_Subp_Decl
                   | Ada_Null_Subp_Decl
                   | Ada_Abstract_Subp_Decl;
   --  Extract documentation for subprograms.

end GNATdoc.Comments.Extractor;
