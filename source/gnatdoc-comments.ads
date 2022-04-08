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

private with Ada.Containers.Vectors;

private with Langkit_Support.Slocs;

private with VSS.String_Vectors;
private with VSS.Strings;

package GNATdoc.Comments is

   type Structured_Comment is tagged limited private;

   type Structured_Comment_Access is access all Structured_Comment'Class;

   type Section_Kind is
     (Raw,                --  Raw text of the documentation, extracted from
      --                      comments
      Breif,              --  Breif description of the entity
      --                      ??? not supported
      Description,        --  Full description of the entity
      Parameter,          --  Description of the parameter
      Returns,            --  Description of the return value
      Raised_Exception);  --  Description of the raised exception

   type Section is tagged limited private;

   type Section_Access is access all Section'Class;

   procedure Free (Item : in out Structured_Comment_Access);
   --  Deallocate memory occupied by structured comment.

private

   type Section is tagged limited record
      Kind             : Section_Kind;
      Name             : VSS.Strings.Virtual_String;
      Text             : VSS.String_Vectors.Virtual_String_Vector;

      --  Members below are used by comment extractor only.

      Exact_Start_Line : Langkit_Support.Slocs.Line_Number := 0;
      Exact_End_Line   : Langkit_Support.Slocs.Line_Number := 0;
      Group_Start_Line : Langkit_Support.Slocs.Line_Number := 0;
      Group_End_Line   : Langkit_Support.Slocs.Line_Number := 0;
      --  First and last lines that may contain comments for the documentation
      --  of the given parameter. Exact range is for given parameter only,
      --  but group documentation is for few grouped parameters. Exact range
      --  is used to fill raw documentation located "inside" the subprogram
      --  declaration (when aspects are present).
   end record;

   package Section_Vectors is
     new Ada.Containers.Vectors (Positive, Section_Access);

   type Structured_Comment is tagged limited record
      Sections : Section_Vectors.Vector;
   end record;

end GNATdoc.Comments;
