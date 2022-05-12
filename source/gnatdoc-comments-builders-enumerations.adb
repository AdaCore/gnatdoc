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

package body GNATdoc.Comments.Builders.Enumerations is

   -----------
   -- Build --
   -----------

   procedure Build
     (Self            : in out Enumeration_Components_Builder;
      Documentation   : not null GNATdoc.Comments.Structured_Comment_Access;
      Options         : GNATdoc.Comments.Extractor.Extractor_Options;
      Node            : Libadalang.Analysis.Enum_Type_Def'Class;
      Advanced_Groups : out Boolean;
      Last_Section    : out GNATdoc.Comments.Section_Access;
      Minimum_Indent  : out Langkit_Support.Slocs.Column_Number) is
   begin
      Self.Initialize (Documentation, Options, Node);

      for Literal of Node.F_Enum_Literals loop
         Self.Process_Component_Declaration (Literal);
         Self.Process_Defining_Name (Enumeration_Literal, Literal.F_Name);
      end loop;

      Advanced_Groups := Self.Advanced_Groups;
      Last_Section    := Self.Last_Section;
      Minimum_Indent  := Self.Minimum_Indent;
   end Build;

end GNATdoc.Comments.Builders.Enumerations;
