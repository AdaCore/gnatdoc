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

--  Test driver to run documentation extractor on all supported nodes of the
--  unit tree and dump content of the extracted documentation.

with Ada.Text_IO;
with Ada.Wide_Wide_Text_IO;   use Ada.Wide_Wide_Text_IO;

with GNATdoc.Messages;
with VSS.Application;         use VSS.Application;
with VSS.JSON.Pull_Readers.Simple;
with VSS.JSON.Streams;
with VSS.Regular_Expressions;
with VSS.Strings;             use VSS.Strings;
with VSS.Strings.Conversions; use VSS.Strings.Conversions;
with VSS.Text_Streams.File_Input;

with Libadalang.Analysis;     use Libadalang.Analysis;
with Libadalang.Common;       use Libadalang.Common;

with GNATdoc.Comments.Debug;
with GNATdoc.Comments.Extractor;
with GNATdoc.Comments.Options;

procedure Test_Extractor is

   procedure Load_Options;

   function Process (Node : Ada_Node'Class) return Visit_Status;

   Options : GNATdoc.Comments.Options.Extractor_Options;

   ------------------
   -- Load_Options --
   ------------------

   procedure Load_Options is
      use all type VSS.JSON.Streams.JSON_Stream_Element_Kind;

      Stream : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader : VSS.JSON.Pull_Readers.Simple.JSON_Simple_Pull_Reader;
      Key    : Virtual_String;

   begin
      Stream.Open (Arguments.Element (1), "utf-8");
      Reader.Set_Stream (Stream'Unchecked_Access);

      while not Reader.At_End loop
         case Reader.Read_Next is
            when Start_Document | End_Document | Start_Object | End_Object =>
               null;

            when Key_Name =>
               Key := Reader.Key_Name;

            when String_Value =>
               if Key = "style" then
                  Options.Style :=
                    GNATdoc.Comments.Options.Documentation_Style'
                      Wide_Wide_Value
                        (To_Wide_Wide_String (Reader.String_Value));

               elsif Key = "documentation_pattern" then
                  if not Reader.String_Value.Is_Empty then
                     Options.Pattern :=
                       VSS.Regular_Expressions.To_Regular_Expression
                         (Reader.String_Value);

                     if not Options.Pattern.Is_Valid then
                        raise Program_Error;
                     end if;
                  end if;

               else
                  raise Program_Error;
               end if;

            when others =>
               raise Program_Error
                 with VSS.JSON.Streams.JSON_Stream_Element_Kind'Image
                        (Reader.Element_Kind);
         end case;
      end loop;
   end Load_Options;

   -------------
   -- Process --
   -------------

   function Process (Node : Ada_Node'Class) return Visit_Status is

      procedure Extract_And_Dump;
      --  Extract documentation and dump structured comment.

      ----------------------
      -- Extract_And_Dump --
      ----------------------

      procedure Extract_And_Dump is
      begin
         Put_Line ("**************************");

         declare
            Comment  : GNATdoc.Comments.Structured_Comment;
            Messages : GNATdoc.Messages.Message_Container;

         begin
            GNATdoc.Comments.Extractor.Extract
              (Node.As_Basic_Decl, Options, Comment, Messages);
            GNATdoc.Comments.Debug.Dump (Comment);
         end;

         Put_Line ("**************************");
      end Extract_And_Dump;

   begin
      Ada.Text_IO.Put_Line (Node.Image);

      case Node.Kind is
         when Ada_Package_Decl =>
            Extract_And_Dump;

            return Into;

         when Ada_Subp_Decl | Ada_Null_Subp_Decl | Ada_Abstract_Subp_Decl
            | Ada_Expr_Function | Ada_Subp_Body
            | Ada_Concrete_Type_Decl
            | Ada_Subtype_Decl
            | Ada_Exception_Decl
            | Ada_Object_Decl
            | Ada_Entry_Decl
            | Ada_Entry_Body
         =>
            Extract_And_Dump;

            return Over;

         when Ada_Generic_Package_Decl | Ada_Generic_Subp_Decl =>
            Extract_And_Dump;

            return Into;

         when Ada_Record_Rep_Clause =>
            --  These nodes doesn't have own documentation, ignore them.

            return Over;

         when Ada_Single_Task_Decl | Ada_Task_Type_Decl
            | Ada_Single_Protected_Decl | Ada_Protected_Type_Decl
            | Ada_Protected_Body
         =>
            Extract_And_Dump;

            return Into;

         when Ada_Generic_Formal_Part =>
            --  Formal part of the generic is processed in generic
            --  declaration processing.

            return Over;

         when Ada_Package_Renaming_Decl | Ada_Subp_Renaming_Decl
            | Ada_Generic_Package_Renaming_Decl
            | Ada_Generic_Subp_Renaming_Decl
         =>
            Extract_And_Dump;

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

   Load_Options;

   Unit.Root.Traverse (Process'Access);
end Test_Extractor;
