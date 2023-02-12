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

with Ada.Text_IO; use Ada.Text_IO;

with Libadalang.Common;

package body GNATdoc.Comments.Builders.Private_Types is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -----------
   -- Build --
   -----------

   procedure Build
     (Self           : in out Private_Type_Builder;
      Documentation  : not null GNATdoc.Comments.Structured_Comment_Access;
      Options        : GNATdoc.Comments.Options.Extractor_Options;
      Node           : Libadalang.Analysis.Type_Decl'Class;
      Last_Section   : out GNATdoc.Comments.Section_Access;
      Minimum_Indent : out Langkit_Support.Slocs.Column_Number)
   is
      function Process (Node : Ada_Node'Class) return Visit_Status;

      -------------
      -- Process --
      -------------

      function Process (Node : Ada_Node'Class) return Visit_Status is
         Done    : Boolean;
         Control : Visit_Status;

      begin
         Self.Process_Discriminants_Node (Node, Done, Control);

         if Done then
            return Control;
         end if;

         Put_Line (Standard_Error, Image (Node));

         raise Program_Error with Ada_Node_Kind_Type'Image (Node.Kind);
      end Process;

      Discriminants : constant Discriminant_Part := Node.F_Discriminants;

   begin
      Self.Initialize (Documentation, Options, Node);

      if not Discriminants.Is_Null then
         Discriminants.Traverse (Process'Access);
      end if;

      Self.Restart_Component_Group (Node.Sloc_Range.End_Line);

      Self.Fill_Structured_Comment (Node, Options.Pattern);

      Last_Section   := Self.Last_Section;
      Minimum_Indent := Self.Minimum_Indent;
   end Build;

end GNATdoc.Comments.Builders.Private_Types;
