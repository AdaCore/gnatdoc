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

--  Test driver to run documentation extractor on all supported nodes of the
--  unit tree and dump content of the extracted documentation.

with Ada.Text_IO;
with Ada.Wide_Wide_Text_IO;   use Ada.Wide_Wide_Text_IO;

with VSS.Application;         use VSS.Application;
with VSS.Strings.Conversions; use VSS.Strings.Conversions;

with Libadalang.Analysis;     use Libadalang.Analysis;
with Libadalang.Common;       use Libadalang.Common;

with GNATdoc.Comments.Debug;
with GNATdoc.Comments.Extractor;
with GNATdoc.Comments.Options;

procedure Test_Extractor is

   function Process (Node : Ada_Node'Class) return Visit_Status;

   -------------
   -- Process --
   -------------

   function Process (Node : Ada_Node'Class) return Visit_Status is
   begin
      Ada.Text_IO.Put_Line (Node.Image);

      case Node.Kind is
         when Ada_Subp_Decl | Ada_Null_Subp_Decl | Ada_Abstract_Subp_Decl
            | Ada_Expr_Function
         =>
            Put_Line ("**************************");

            declare
               Comment : GNATdoc.Comments.Structured_Comment_Access;
               Options : GNATdoc.Comments.Options.Extractor_Options :=
                 (Style    =>
                    GNATdoc.Comments.Options.Documentation_Style
                      'Wide_Wide_Value (To_Wide_Wide_String
                    (Arguments.Element (1))),
                  Fallback => False);

            begin
               Comment :=
                 GNATdoc.Comments.Extractor.Extract
                   (Node.As_Basic_Decl, Options);
               GNATdoc.Comments.Debug.Dump (Comment.all);
               GNATdoc.Comments.Free (Comment);
            end;

            Put_Line ("**************************");

            return Over;

         when others =>
            return Into;
      end case;
   end Process;

   Context : Analysis_Context := Create_Context;
   Unit    : Analysis_Unit :=
     Context.Get_From_File (To_UTF_8_String (Arguments.Element (2)));

begin
   if Unit.Has_Diagnostics then
      for D of Unit.Diagnostics loop
         Ada.Text_IO.Put_Line (Unit.Format_GNU_Diagnostic (D));
      end loop;

      return;
   end if;

   Unit.Root.Traverse (Process'Access);
end Test_Extractor;
