------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
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

private package GNATdoc.Comments.Extractor.Trailing is

   procedure Process
     (Node     : Libadalang.Analysis.Basic_Decl'Class;
      Sections : in out GNATdoc.Comments.Section_Vectors.Vector);

private

   type Kinds is (None, Subprogram, Parameter, Returns);

   type Entity_Kind is (None, Entity);

   type Entity_Group_Kind is (None, Subprogram);

   type Component_Group_Kind is (None, Parameter, Returns);

   type Info is record
      Kind     : Kinds := None;
      Indent   : Libadalang.Slocs.Column_Number := 0;
      Sections : Section_Vectors.Vector;
   end record;

   type Entity_Information (Kind : Entity_Kind := None) is record
      Indent  : Libadalang.Slocs.Column_Number := 0;
      Section : GNATdoc.Comments.Section_Access;
   end record;

   type Entity_Group_Information (Kind : Entity_Group_Kind := None) is record
      case Kind is
         when None =>
            null;

         when Subprogram =>
            Indent   : Libadalang.Slocs.Column_Number := 0;
            Sections : Section_Vectors.Vector;
      end case;
   end record;

   type Component_Group_Information
     (Kind : Component_Group_Kind := None) is
   record
      Sections : Section_Vectors.Vector;
   end record;

   type Line_Information is record
      Item            : Info;

      Entity          : Entity_Information;
      Component_Group : Component_Group_Information;
      Entity_Group    : Entity_Group_Information;
   end record;

   type Line_Information_Array is
     array (Libadalang.Slocs.Line_Number range <>) of Line_Information;

end GNATdoc.Comments.Extractor.Trailing;
