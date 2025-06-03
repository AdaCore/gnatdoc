------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2024-2025, AdaCore                     --
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

with VSS.Strings.Formatters.Generic_Enumerations;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.Text_Streams.Standards;

with GNATdoc.Entities;
with GNATdoc.Projects;

package body GNATdoc.Backend.Test is

   Dump_Projects_Option : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "test-dump-projects",
      Description => "Dump list of projects to be processed/excluded");

   Dump_Entities_Tree_Option : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "test-dump-entities-tree",
      Description => "Dump tree of processed entities");

   procedure Dump_Entities_Tree;

   package Entity_Kind_Formatters is
     new VSS.Strings.Formatters.Generic_Enumerations
           (GNATdoc.Entities.Entity_Kind);

   ------------------------------
   -- Add_Command_Line_Options --
   ------------------------------

   overriding procedure Add_Command_Line_Options
     (Self   : Test_Backend;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      Parser.Add_Option (Dump_Projects_Option);
      Parser.Add_Option (Dump_Entities_Tree_Option);
   end Add_Command_Line_Options;

   ------------------------
   -- Dump_Entities_Tree --
   ------------------------

   procedure Dump_Entities_Tree is
      Output : VSS.Text_Streams.Output_Text_Stream'Class :=
        VSS.Text_Streams.Standards.Standard_Output;
      Offset : VSS.Strings.Character_Count := 0;

      procedure Dump (Entity : GNATdoc.Entities.Entity_Information);

      procedure Dump_Entity_Summary
        (Entity  : GNATdoc.Entities.Entity_Information;
         Success : in out Boolean);
      --  Outputs summary information

      procedure Dump_Entity_Unknown
        (Entity  : GNATdoc.Entities.Entity_Reference;
         Success : in out Boolean);
      --  Outputs summary information for unknown entity

      ----------
      -- Dump --
      ----------

      procedure Dump (Entity : GNATdoc.Entities.Entity_Information) is
         use type VSS.Strings.Character_Count;
         use type VSS.Strings.Virtual_String;

         Section_Template : constant
           VSS.Strings.Templates.Virtual_String_Template :=
             "{}{}:";
         Parent_Template  : constant
           VSS.Strings.Templates.Virtual_String_Template :=
             "{}Parent type: '{}'";

         Success  : Boolean := True;

      begin
         Dump_Entity_Summary (Entity, Success);

         if not Entity.Packages.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Packages")),
               Success);

            Offset := @ + 2;

            for E of Entity.Packages loop
               Dump (E.all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Record_Types.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Record Types")),
               Success);

            Offset := @ + 2;

            for E of Entity.Record_Types loop
               Dump (E.all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Interface_Types.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Interface Types")),
               Success);

            Offset := @ + 2;

            for E of Entity.Interface_Types loop
               Dump (GNATdoc.Entities.To_Entity (E.Signature).all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Tagged_Types.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Tagged Types")),
               Success);

            Offset := @ + 2;

            for E of Entity.Tagged_Types loop
               Dump (GNATdoc.Entities.To_Entity (E.Signature).all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Parent_Type.Signature.Image.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Parent_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image
                    (Entity.Parent_Type.Signature.Image)),
               Success);

            Offset := @ - 2;
         end if;

         if not Entity.Progenitor_Types.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Progenitor Types")),
               Success);

            Offset := @ + 2;

            for E of Entity.Progenitor_Types loop
               if GNATdoc.Entities.To_Entity.Contains (E.Signature) then
                  Dump (GNATdoc.Entities.To_Entity (E.Signature).all);

               else
                  Dump_Entity_Unknown (E, Success);
               end if;
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Subtypes.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Subtypes")),
               Success);

            Offset := @ + 2;

            for E of Entity.Subtypes loop
               Dump (E.all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Constants.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Constants")),
               Success);

            Offset := @ + 2;

            for E of Entity.Constants loop
               Dump (E.all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Subprograms.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Subprograms")),
               Success);

            Offset := @ + 2;

            for E of Entity.Subprograms loop
               Dump (E.all);
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Belongs_Constants.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image ("Belongs Constants")),
               Success);

            Offset := @ + 2;

            for E of Entity.Belongs_Constants loop
               if GNATdoc.Entities.To_Entity.Contains (E.Signature) then
                  Dump (GNATdoc.Entities.To_Entity (E.Signature).all);

               else
                  Dump_Entity_Unknown (E, Success);
               end if;
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;

         if not Entity.Belongs_Subprograms.Is_Empty then
            Offset := @ + 2;

            Output.Put_Line
              (Section_Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
                  VSS.Strings.Formatters.Strings.Image
                    ("Belongs Subprograms")),
               Success);

            Offset := @ + 2;

            for E of Entity.Belongs_Subprograms loop
               if GNATdoc.Entities.To_Entity.Contains (E.Signature) then
                  Dump (GNATdoc.Entities.To_Entity (E.Signature).all);

               else
                  Dump_Entity_Unknown (E, Success);
               end if;
            end loop;

            Offset := @ - 2;
            Offset := @ - 2;
         end if;
      end Dump;

      -------------------------
      -- Dump_Entity_Summary --
      -------------------------

      procedure Dump_Entity_Summary
        (Entity  : GNATdoc.Entities.Entity_Information;
         Success : in out Boolean)
      is
         use type VSS.Strings.Character_Count;

         Summary_Template  : constant
           VSS.Strings.Templates.Virtual_String_Template :=
             "{}{}{}{}{} ({}) '{}'";

      begin
         Output.Put_Line
           (Summary_Template.Format
              (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
               VSS.Strings.Formatters.Strings.Image
                 (VSS.Strings.Virtual_String'
                      (if Entity.Is_Private then "-" else "+")),
               VSS.Strings.Formatters.Strings.Image
                 (VSS.Strings.Virtual_String'
                      (if Entity.Documentation.Is_Private then "/" else " ")),
               VSS.Strings.Formatters.Strings.Image
                 (VSS.Strings.Virtual_String'
                      (if GNATdoc.Entities.To_Entity.Contains
                           (Entity.Signature)
                         then " " else "?")),
               VSS.Strings.Formatters.Strings.Image (Entity.Name),
               Entity_Kind_Formatters.Image (Entity.Kind),
               VSS.Strings.Formatters.Strings.Image (Entity.Signature.Image)),
            Success);
      end Dump_Entity_Summary;

      -------------------------
      -- Dump_Entity_Unknown --
      -------------------------

      procedure Dump_Entity_Unknown
        (Entity  : GNATdoc.Entities.Entity_Reference;
         Success : in out Boolean)
      is
         use type VSS.Strings.Character_Count;

         Unknown_Template  : constant
           VSS.Strings.Templates.Virtual_String_Template :=
             "{}# ?{} '{}'";

      begin
         Output.Put_Line
           (Unknown_Template.Format
              (VSS.Strings.Formatters.Strings.Image (Offset * ' '),
               VSS.Strings.Formatters.Strings.Image (Entity.Qualified_Name),
               VSS.Strings.Formatters.Strings.Image (Entity.Signature.Image)),
            Success);
      end Dump_Entity_Unknown;

   begin
      Dump (GNATdoc.Entities.Globals);
   end Dump_Entities_Tree;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out Test_Backend) is
   begin
      if Self.Dump_Projects then
         GNATdoc.Projects.Test_Dump_Projects;
      end if;

      if Self.Dump_Entities_Tree then
         Dump_Entities_Tree;
      end if;
   end Generate;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out Test_Backend) is
   begin
      Abstract_Backend (Self).Initialize;
   end Initialize;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out Test_Backend) return VSS.Strings.Virtual_String is
   begin
      return "test";
   end Name;

   ----------------------------------
   -- Process_Command_Line_Options --
   ----------------------------------

   overriding procedure Process_Command_Line_Options
     (Self   : in out Test_Backend;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      Self.Dump_Projects := Parser.Is_Specified (Dump_Projects_Option);
      Self.Dump_Entities_Tree :=
        Parser.Is_Specified (Dump_Entities_Tree_Option);
   end Process_Command_Line_Options;

end GNATdoc.Backend.Test;
