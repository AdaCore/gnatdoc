------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                        Copyright (C) 2025, AdaCore                       --
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

private package GNATdoc.Comments.Extractor.Code_Snippets is

   procedure Fill_Code_Snippet
     (Node        : Libadalang.Analysis.Ada_Node'Class;
      First_Token : Token_Reference;
      Last_Token  : Token_Reference;
      Sections    : in out Section_Vectors.Vector);
   --  Extract code snippet between given tokens, remove all comments from it,
   --  and create code snippet section of the structured comment.
   --
   --  @param Node         Declaration or specification node
   --  @param First_Token  First token of the range to be processed
   --  @param Last_Token   Last token of the range to be processed
   --  @param Sections     List of sections to append new section.

end GNATdoc.Comments.Extractor.Code_Snippets;
