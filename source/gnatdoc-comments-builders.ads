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

--  This packages provides base tagged type to construct set of sections of
--  structured comment.

private with Langkit_Support.Slocs;
private with Libadalang.Analysis;

private with GNATdoc.Comments.Options;

private package GNATdoc.Comments.Builders is

   type Abstract_Components_Builder is abstract tagged limited private;

private

   package Section_Vectors is
     new Ada.Containers.Vectors (Positive, Section_Access);

   type Abstract_Components_Builder is abstract tagged limited record
      Style            : GNATdoc.Comments.Options.Documentation_Style;

      Documentation    : GNATdoc.Comments.Structured_Comment_Access;
      --  Documentation to fill.

      Advanced_Groups  : Boolean;
      --  Process advanced groups of the components in GNAT style.

      Location         : Langkit_Support.Slocs.Source_Location_Range;
      --  Location of the currently processed component.

      Previous_Group   : Section_Vectors.Vector;
      Group_Start_Line : Langkit_Support.Slocs.Line_Number;
      Group_End_Line   : Langkit_Support.Slocs.Line_Number;
      Last_Section     : Section_Access;
      Minimum_Indent   : Langkit_Support.Slocs.Column_Number;

      Next_Start_Line  : Langkit_Support.Slocs.Line_Number;
      --  First line after currently processed component. For GNAT style it is
      --  used as starting line of the secondary documentation of the
      --  component. For Leading style it is used as first line of secondary
      --  documentation for the next component.
   end record;

   procedure Initialize
     (Self          : in out Abstract_Components_Builder'Class;
      Documentation : not null GNATdoc.Comments.Structured_Comment_Access;
      Options       : GNATdoc.Comments.Options.Extractor_Options;
      Node          : Libadalang.Analysis.Ada_Node'Class);

   procedure Process_Component_Declaration
     (Self : in out Abstract_Components_Builder'Class;
      Node : Libadalang.Analysis.Ada_Node'Class);
   --  Prepare to construct set of sections for declaration. Declaration can
   --  define few defining names, Process_Defining_Name subprogram must be
   --  called to create actual section for each such name.

   procedure Process_Defining_Name
     (Self : in out Abstract_Components_Builder'Class;
      Kind : GNATdoc.Comments.Section_Kind;
      Node : Libadalang.Analysis.Defining_Name'Class);
   --  Create section for the given defining name.

   procedure Restart_Component_Group
     (Self       : in out Abstract_Components_Builder'Class;
      Start_Line : Langkit_Support.Slocs.Line_Number);
   --  When processing of the component groups (group of declarations that
   --  shares documentation) is enabled, call of this subprogram reset
   --  tracking of the group. It must be used then some syntactic elements
   --  breaks group, for instance, t shpuld be called after processing of the
   --  discriminants of the record type, and before processing of the fields.

end GNATdoc.Comments.Builders;
