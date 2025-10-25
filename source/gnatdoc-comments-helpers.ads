------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2025, AdaCore                     --
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

with VSS.String_Vectors;

with Libadalang.Analysis;

with GNATdoc.Comments.Options;

package GNATdoc.Comments.Helpers is

   procedure Get_Plain_Text_Documentation
     (Name          : Libadalang.Analysis.Defining_Name'Class;
      Origin        : Libadalang.Analysis.Ada_Node'Class;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Code_Snippet  : out VSS.String_Vectors.Virtual_String_Vector;
      Documentation : out VSS.String_Vectors.Virtual_String_Vector)
     with Pre => not Name.Is_Null;
   --  Return code snippet and documentation for the given node in plain text
   --  format.
   --
   --  Convenience function for ALS.
   --
   --  @param Name           Defining name of the entity
   --  @param Origin
   --    Node to resolve visible declaration part of the defining name
   --  @param Options        Documentation extractor's options
   --  @param Code_Snippet   Code snippet of the most visible declaration
   --  @param Documentation  Extracted documentation

   function Get_Ada_Code_Snippet
     (Self : Structured_Comment'Class)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Return text of the subprogram specification as single string using
   --  given line terminator.

   function Get_Plain_Text_Description
     (Documentation : Structured_Comment)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Return description as plain text.

end GNATdoc.Comments.Helpers;
