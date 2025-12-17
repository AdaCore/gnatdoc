------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2023-2025, AdaCore                     --
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

with Ada.Containers.Ordered_Sets;

with VSS.Characters.Latin;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;

with GNATdoc.Comments.RST_Helpers;
with GNATdoc.Configuration;
with GNATdoc.Entities; use GNATdoc.Entities;
with Streams;

package body GNATdoc.Backend.RST is

   procedure Generate_Documentation
     (Self   : in out RST_Backend_Base'Class;
      Entity : Entity_Information);
   --  Generate RTS file for given entity.

   OOP_Style_Option : constant VSS.Command_Line.Binary_Option :=
     (Short_Name  => <>,
      Long_Name   => "rst-oop-style",
      Description =>
        VSS.Strings.To_Virtual_String
          ("Group subprograms by tagged types, generating a page for each"
           & " tagged type"));

   ------------------------------
   -- Add_Command_Line_Options --
   ------------------------------

   overriding procedure Add_Command_Line_Options
     (Self   : RST_Backend_Base;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      Parser.Add_Option (OOP_Style_Option);
   end Add_Command_Line_Options;

   -----------------------------
   -- Documentation_File_Name --
   -----------------------------

   function Documentation_File_Name
     (Entity : Entity_Information) return VSS.Strings.Virtual_String is
   begin
      return Result : VSS.Strings.Virtual_String := "ada___" do
         declare
            Iterator : VSS.Strings.Character_Iterators.Character_Iterator :=
              Entity.Qualified_Name.Before_First_Character;

         begin
            while Iterator.Forward loop
               declare
                  use type VSS.Characters.Virtual_Character;

                  C : constant VSS.Characters.Virtual_Character :=
                    Iterator.Element;

               begin
                  if C = VSS.Characters.Latin.Full_Stop then
                     Result.Append ("__");

                  else
                     Result.Append
                       (VSS.Characters.Get_Simple_Lowercase_Mapping (C));
                  end if;
               end;
            end loop;

            Result.Append
              (VSS.Strings.To_Virtual_String
                 (if Entity.Is_Specification then "___spec" else "___body"));
         end;

         Result.Append (".rst");
      end return;
   end Documentation_File_Name;

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out RST_Backend_Base) is
   begin
      for Item of Globals.Packages loop
         if not Is_Private_Entity (Item) then
            Self.Generate_Documentation (Item.all);
         end if;
      end loop;
   end Generate;

   ----------------------------
   -- Generate_Documentation --
   ----------------------------

   procedure Generate_Documentation
     (Self   : in out RST_Backend_Base'Class;
      Entity : Entity_Information)
   is
      use type VSS.Strings.Character_Count;

      Name    : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create_From_Base
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (Documentation_File_Name (Entity))),
           GNATdoc.Configuration.Provider.Output_Directory
             (Self.Name).Full_Name);

      File    : Streams.Output_Text_Stream;
      Success : Boolean := True;

      procedure Generate_Constant_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String);
      --  Generate documentation for the given constant.

      procedure Generate_Subprogram_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String);
      --  Generate documentation for the given subprogram.

      -------------------------------------
      -- Generate_Constant_Documentation --
      -------------------------------------

      procedure Generate_Constant_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String)
      is
         use type VSS.Strings.Virtual_String;

      begin
         File.New_Line (Success);

         File.Put (Indent, Success);
         File.Put (".. ada:object:: ", Success);

         File.Put (Entity.Name, Success);
         File.New_Line (Success);
         File.Put (Indent, Success);
         File.Put ("    :package: ", Success);
         File.Put (Package_Name, Success);
         File.New_Line (Success);
         File.New_Line (Success);

         File.Put_Lines
           (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
              (Indent        => Indent & "    ",
               Documentation => Entity.Documentation,
               Pass_Through  => False,
               Code_Snippet  => False),
            Success);
         File.New_Line (Success);
      end Generate_Constant_Documentation;

      ---------------------------------------
      -- Generate_Subprogram_Documentation --
      ---------------------------------------

      procedure Generate_Subprogram_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String)
      is
         use type VSS.Strings.Virtual_String;

      begin
         File.New_Line (Success);

         case Entity.Kind is
            when Ada_Function =>
               File.Put (Indent, Success);
               File.Put (".. ada:function:: ", Success);

            when Ada_Procedure =>
               File.Put (Indent, Success);
               File.Put (".. ada:procedure:: ", Success);

            when others =>
               raise Program_Error;
         end case;

         File.Put (Indent, Success);
         File.Put (Entity.RST_Profile, Success);
         File.New_Line (Success);
         File.Put (Indent, Success);
         File.Put ("    :package: ", Success);
         File.Put (Package_Name, Success);
         File.New_Line (Success);
         File.New_Line (Success);

         File.Put_Lines
           (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
              (Indent        => Indent & "    ",
               Documentation => Entity.Documentation,
               Pass_Through  => False,
               Code_Snippet  => False),
            Success);
         File.New_Line (Success);
      end Generate_Subprogram_Documentation;

   begin
      File.Open (Name);

      File.New_Line (Success);
      File.Put (Entity.Qualified_Name, Success);
      File.New_Line (Success);
      File.Put ((Entity.Qualified_Name.Character_Length + 2) * '*', Success);
      File.New_Line (Success);
      File.New_Line (Success);

      File.Put (".. ada:set_package:: ", Success);
      File.Put (Entity.Qualified_Name, Success);
      File.New_Line (Success);
      File.New_Line (Success);

      File.Put_Lines
        (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
           (Indent        => "",
            Documentation => Entity.Documentation,
            Pass_Through  => False,
            Code_Snippet  => True),
         Success);
      File.New_Line (Success);

      if Self.Alphabetical_Order then
         declare
            Types : Entity_Information_Sets.Set;

         begin
            Types.Union (Entity.Simple_Types);
            Types.Union (Entity.Array_Types);
            Types.Union (Entity.Record_Types);
            Types.Union (Entity.Interface_Types);
            Types.Union (Entity.Tagged_Types);
            Types.Union (Entity.Task_Types);
            Types.Union (Entity.Protected_Types);
            Types.Union (Entity.Access_Types);
            Types.Union (Entity.Subtypes);

            if not Types.Is_Empty then
               File.Put ("-----", Success);
               File.New_Line (Success);
               File.Put ("Types", Success);
               File.New_Line (Success);
               File.Put ("-----", Success);
               File.New_Line (Success);
               File.New_Line (Success);

               for Item of Types loop
                  File.Put (".. ada:type:: type ", Success);
                  File.Put (Item.Name, Success);
                  File.New_Line (Success);
                  File.Put ("    :package: ", Success);
                  File.Put (Entity.Qualified_Name, Success);
                  File.New_Line (Success);
                  File.New_Line (Success);

                  File.Put_Lines
                    (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
                       (Indent        => "    ",
                        Documentation => Item.Documentation,
                        Pass_Through  => False,
                        Code_Snippet  => True),
                     Success);

                  if Self.OOP_Mode
                    and then Item.Kind in Ada_Interface_Type | Ada_Tagged_Type
                  then
                     declare
                        Methods : GNATdoc.Entities.Entity_Reference_Sets.Set;

                     begin
                        Methods.Union (Item.Dispatching_Declared);
                        Methods.Union (Item.Dispatching_Overrided);
                        Methods.Union (Item.Prefix_Callable_Declared);

                        for Method of Methods loop
                           Generate_Subprogram_Documentation
                             ("    ",
                              GNATdoc.Entities.To_Entity
                                (Method.Signature).all,
                              Entity.Qualified_Name);
                        end loop;
                     end;
                  end if;

                  File.New_Line (Success);
               end loop;
            end if;
         end;

      else
         declare

            function Less
              (Left  : not null GNATdoc.Entities.Entity_Information_Access;
               Right : not null GNATdoc.Entities.Entity_Information_Access)
               return Boolean;

            package Entity_Information_Sets is
              new Ada.Containers.Ordered_Sets
                (Element_Type => GNATdoc.Entities.Entity_Information_Access,
                 "<"          => Less,
                 "="          => GNATdoc.Entities."=");

            procedure Union
              (Container : in out Entity_Information_Sets.Set;
               Items     : GNATdoc.Entities.Entity_Information_Sets.Set);

            ----------
            -- Less --
            ----------

            function Less
              (Left  : not null GNATdoc.Entities.Entity_Information_Access;
               Right : not null GNATdoc.Entities.Entity_Information_Access)
               return Boolean
            is
               use type VSS.Strings.Line_Count;
               use type VSS.Strings.Virtual_String;

            begin
               if Left.Location.File < Right.Location.File then
                  return True;

               elsif Left.Location.Line < Right.Location.Line then
                  return True;

               elsif Left.Location.Column < Right.Location.Column then
                  return True;

               else
                  return False;
               end if;
            end Less;

            -----------
            -- Union --
            -----------

            procedure Union
              (Container : in out Entity_Information_Sets.Set;
               Items     : GNATdoc.Entities.Entity_Information_Sets.Set) is
            begin
               for Item of Items loop
                  Container.Insert (Item);
               end loop;
            end Union;

            Types     : Entity_Information_Sets.Set;
            Constants : Entity_Information_Sets.Set;
            Methods   : Entity_Information_Sets.Set;

         begin
            Union (Types, Entity.Simple_Types);
            Union (Types, Entity.Array_Types);
            Union (Types, Entity.Record_Types);
            Union (Types, Entity.Interface_Types);
            Union (Types, Entity.Tagged_Types);
            Union (Types, Entity.Task_Types);
            Union (Types, Entity.Protected_Types);
            Union (Types, Entity.Access_Types);
            Union (Types, Entity.Subtypes);

            if not Types.Is_Empty then
               File.Put ("-----", Success);
               File.New_Line (Success);
               File.Put ("Types", Success);
               File.New_Line (Success);
               File.Put ("-----", Success);
               File.New_Line (Success);
               File.New_Line (Success);

               for Item of Types loop
                  File.Put (".. ada:type:: type ", Success);
                  File.Put (Item.Name, Success);
                  File.New_Line (Success);
                  File.Put ("    :package: ", Success);
                  File.Put (Entity.Qualified_Name, Success);
                  File.New_Line (Success);
                  File.New_Line (Success);

                  File.Put_Lines
                    (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
                       (Indent        => "    ",
                        Documentation => Item.Documentation,
                        Pass_Through  => False,
                        Code_Snippet  => True),
                     Success);

                  if Self.OOP_Mode
                    and then Item.Kind in Ada_Interface_Type | Ada_Tagged_Type
                  then
                     Constants.Clear;
                     Methods.Clear;

                     for Object of Item.Belong_Constants loop
                        if not Is_Private_Entity
                          (GNATdoc.Entities.To_Entity (Object.Signature))
                        then
                           Constants.Insert
                             (GNATdoc.Entities.To_Entity (Object.Signature));
                        end if;
                     end loop;

                     for Object of Constants loop
                        Generate_Constant_Documentation
                          ("    ", Object.all, Entity.Qualified_Name);
                     end loop;

                     for Method of Item.Belong_Subprograms loop
                        if not Is_Private_Entity
                          (GNATdoc.Entities.To_Entity (Method.Signature))
                        then
                           Methods.Insert
                             (GNATdoc.Entities.To_Entity (Method.Signature));
                        end if;
                     end loop;

                     for Method of Methods loop
                        Generate_Subprogram_Documentation
                          ("    ", Method.all, Entity.Qualified_Name);
                     end loop;
                  end if;

                  File.New_Line (Success);
               end loop;
            end if;
         end;
      end if;

      begin
         declare
            Subprograms : GNATdoc.Entities.Entity_Information_Sets.Set;

         begin
            if Self.OOP_Mode then
               for Subprogram of Entity.Belong_Subprograms loop
                  Subprograms.Insert (To_Entity (Subprogram.Signature));
               end loop;

            else
               for Subprogram of Entity.Contain_Subprograms loop
                  Subprograms.Insert
                    (GNATdoc.Entities.To_Entity (Subprogram.Signature));
               end loop;
            end if;

            if not Subprograms.Is_Empty then
               File.Put ("-----------", Success);
               File.New_Line (Success);
               File.Put ("Subprograms", Success);
               File.New_Line (Success);
               File.Put ("-----------", Success);
               File.New_Line (Success);
               File.New_Line (Success);

               for Item of Subprograms loop
                  Generate_Subprogram_Documentation
                    ("", Item.all, Entity.Qualified_Name);
               end loop;
            end if;
         end;
      end;

      File.Close;
   end Generate_Documentation;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out RST_Backend_Base) is
   begin
      Abstract_Backend (Self).Initialize;
   end Initialize;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out RST_Backend) return VSS.Strings.Virtual_String is
   begin
      return "rst";
   end Name;

   ----------------------------------
   -- Process_Command_Line_Options --
   ----------------------------------

   overriding procedure Process_Command_Line_Options
     (Self   : in out RST_Backend_Base;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class) is
   begin
      if Parser.Is_Specified (OOP_Style_Option) then
         Self.OOP_Mode := True;
      end if;
   end Process_Command_Line_Options;

end GNATdoc.Backend.RST;
