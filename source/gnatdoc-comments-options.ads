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

with VSS.Regular_Expressions;

package GNATdoc.Comments.Options is

   type Documentation_Style is
     (GNAT,      --  Advanced GNAT style of the documentation comments
      Leading);  --  Simple leading style of the documentation comments

   type Extractor_Options is record
      Style    : Documentation_Style := GNAT;
      --  Style of the documentation comments.

      Pattern  : VSS.Regular_Expressions.Regular_Expression;
      --  Regular expression to recognize documentation lines in the comments.
      --
      --  All lines that doesn't match given pattern are filtered out.

      Fallback : Boolean             := False;
      --  Control wheather to attempt to extract documentation using simple
      --  "opposite" style (leading comments for GNAT style and trailing
      --  comments for Leading style).
      --
      --  This option is intended to be used by IDE.
   end record;

end GNATdoc.Comments.Options;
