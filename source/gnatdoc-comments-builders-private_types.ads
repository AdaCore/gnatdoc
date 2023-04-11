------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2023, AdaCore                        --
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

--  Structured comment builder for private types with discriminants.

with Libadalang.Analysis;

package GNATdoc.Comments.Builders.Private_Types is

   type Private_Type_Builder is
     new Abstract_Components_Builder with private;

   procedure Build
     (Self           : in out Private_Type_Builder;
      Sections       : not null GNATdoc.Comments.Sections_Access;
      Options        : GNATdoc.Comments.Options.Extractor_Options;
      Node           : Libadalang.Analysis.Type_Decl'Class;
      Last_Section   : out GNATdoc.Comments.Section_Access;
      Minimum_Indent : out Langkit_Support.Slocs.Column_Number);

private

   type Private_Type_Builder is
     new Abstract_Components_Builder with null record;

end GNATdoc.Comments.Builders.Private_Types;
