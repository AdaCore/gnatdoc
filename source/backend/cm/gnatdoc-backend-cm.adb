------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2026, AdaCore                          --
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

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Character_Offsets;
with VSS.Strings.Formatters.Line_Offsets;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with GNATdoc.Comments.CM_Helpers;
with GNATdoc.Comments.Helpers;
with Streams;

package body GNATdoc.Backend.CM is

   use VSS.Strings;
   use VSS.Strings.Formatters.Character_Offsets;
   use VSS.Strings.Formatters.Line_Offsets;
   use VSS.String_Vectors;

   function Is_Top_Level_Package_Like
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return Boolean;

   function Output_File
     (Self   : CM_Backend;
      Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return GNATCOLL.VFS.Virtual_File;

   function Indent_Lines
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.String_Vectors.Virtual_String_Vector;

   procedure Generate_Entity
     (Self           : CM_Backend;
      Entity         : not null GNATdoc.Entities.Entity_Information_Access;
      Output         : in out Streams.Output_Text_Stream;
      Current_Source : in out VSS.Strings.Virtual_String;
      Is_Open        : in out Boolean;
      Success        : in out Boolean);

   function Is_Legacy_False_Exclude
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return Boolean;

   -------------------------------
   -- Is_Top_Level_Package_Like --
   -------------------------------

   function Is_Top_Level_Package_Like
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return Boolean
   is
   begin
      return
        Entity.Enclosing.Image.Is_Empty
          and then Entity.Kind in GNATdoc.Entities.Ada_Package_Declaration
                                | GNATdoc.Entities.Ada_Package_Body
                                | GNATdoc.Entities
                                    .Ada_Generic_Package_Declaration;
   end Is_Top_Level_Package_Like;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out CM_Backend) is
      Current_Source : VSS.Strings.Virtual_String;
      Output         : Streams.Output_Text_Stream;
      Is_Open        : Boolean := False;
      Success        : Boolean := True;

   begin
      for Entity of GNATdoc.Entities.Globals.Contain_Entities loop
         Self.Generate_Entity
           (Entity         => Entity,
            Output         => Output,
            Current_Source => Current_Source,
            Is_Open        => Is_Open,
            Success        => Success);
      end loop;

      if Is_Open then
         Output.Close;
      end if;
   end Generate;

   ------------------
   -- Indent_Lines --
   ------------------

   function Indent_Lines
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.String_Vectors.Virtual_String_Vector
   is
      Result : VSS.String_Vectors.Virtual_String_Vector;

   begin
      for Line of Text loop
         Result.Append ("   " & Line);
      end loop;

      return Result;
   end Indent_Lines;

   -----------------------------
   -- Is_Legacy_False_Exclude --
   -----------------------------

   function Is_Legacy_False_Exclude
     (Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return Boolean is
   begin
      return GNATdoc.Comments.CM_Helpers.Has_Exclude_Tag_Mention
        (Entity.Documentation);
   end Is_Legacy_False_Exclude;

   ---------------------
   -- Generate_Entity --
   ---------------------

   procedure Generate_Entity
     (Self           : CM_Backend;
      Entity         : not null GNATdoc.Entities.Entity_Information_Access;
      Output         : in out Streams.Output_Text_Stream;
      Current_Source : in out VSS.Strings.Virtual_String;
      Is_Open        : in out Boolean;
      Success        : in out Boolean)
   is
      Header_Template : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "***** {}:{}:{}:{}";
      Doc_Line_Template : constant
        VSS.Strings.Templates.Virtual_String_Template :=
          "--- Doc.Line: {}";
      Code_Snippet    : constant VSS.String_Vectors.Virtual_String_Vector :=
        Indent_Lines
          (GNATdoc.Comments.Helpers.Get_Ada_Code_Snippet
             (Entity.Documentation));
      Documentation   : constant VSS.String_Vectors.Virtual_String_Vector :=
        GNATdoc.Comments.CM_Helpers.Get_CM_Documentation
          (Entity.Documentation);
      Source_File     : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create_From_UTF8
          (VSS.Strings.Conversions.To_UTF_8_String (Entity.Location.File));
      Legacy_Blocks   : constant
        GNATdoc.Comments.CM_Helpers.Legacy_Doc_Block_Vectors.Vector :=
          GNATdoc.Comments.CM_Helpers.Get_Legacy_Doc_Blocks
           (Entity.Documentation);
      Legacy_Column   : constant VSS.Strings.Character_Offset :=
         (if Entity.Location.Column > 2
          then Entity.Location.Column - 2
          else 1);

   begin
      if Is_Top_Level_Package_Like (Entity) then
         for Nested of Entity.Contain_Entities loop
            Self.Generate_Entity
              (Entity         => Nested,
               Output         => Output,
               Current_Source => Current_Source,
               Is_Open        => Is_Open,
               Success        => Success);
         end loop;

         return;
      end if;

      if Is_Included (Entity) or else Is_Legacy_False_Exclude (Entity) then
         if not Is_Open or else Current_Source /= Entity.Location.File then
            if Is_Open then
               Output.Close;
            end if;

            Output.Open (Self.Output_File (Entity));
            Current_Source := Entity.Location.File;
            Is_Open := True;
         end if;

         Output.Put_Line
           (Header_Template.Format
              (VSS.Strings.Formatters.Strings.Image
                 (VSS.Strings.Conversions.To_Virtual_String
                    (Source_File.Display_Base_Name)),
               Image (Entity.Location.Line),
               Image (Entity.Location.Column),
               VSS.Strings.Formatters.Strings.Image (Entity.Name)),
            Success);
         Output.Put_Line ("--- Src:", Success);
         Output.Put_Lines (Code_Snippet, Success);

         if not Documentation.Is_Empty then
            Output.Put_Line ("--- Structured Comment:", Success);
            Output.Put_Lines (Documentation, Success);
         end if;

         Output.New_Line (Success);

         for Block of Legacy_Blocks loop
            declare
               Legacy_Line : constant VSS.Strings.Line_Offset :=
                 (if Block.Line > 0 then Block.Line else Entity.Location.Line);

            begin
               Output.Put_Line
                 (Header_Template.Format
                    (VSS.Strings.Formatters.Strings.Image
                       (VSS.Strings.Conversions.To_Virtual_String
                          (Source_File.Display_Base_Name)),
                     Image (Legacy_Line),
                     Image (Legacy_Column),
                     VSS.Strings.Formatters.Strings.Image (Block.Name)),
                  Success);
               Output.Put_Line
                 (Doc_Line_Template.Format (Image (Legacy_Line)),
                  Success);

               if not Block.Text.Is_Empty then
                  Output.Put_Line
                    ("--- Doc.Text:   " & Block.Text.Element (1),
                     Success);

                  for J in 2 .. Block.Text.Length loop
                     Output.Put_Line (Block.Text.Element (J), Success);
                  end loop;
               else
                  Output.Put_Line ("--- Doc.Text:", Success);
               end if;

               Output.New_Line (Success);
            end;
         end loop;
      end if;

      for Nested of Entity.Contain_Entities loop
         Self.Generate_Entity
           (Entity         => Nested,
            Output         => Output,
            Current_Source => Current_Source,
            Is_Open        => Is_Open,
            Success        => Success);
      end loop;
   end Generate_Entity;

   -----------------
   -- Output_File --
   -----------------

   function Output_File
     (Self   : CM_Backend;
      Entity : not null GNATdoc.Entities.Entity_Information_Access)
      return GNATCOLL.VFS.Virtual_File
   is
      Source_File : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create_From_UTF8
          (VSS.Strings.Conversions.To_UTF_8_String (Entity.Location.File));

   begin
      return GNATCOLL.VFS.Create_From_Dir
        (Self.Output_Root,
         GNATCOLL.VFS.Filesystem_String
           (Source_File.Display_Base_Name & ".cm"));
   end Output_File;

end GNATdoc.Backend.CM;