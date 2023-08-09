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

with VSS.Characters.Latin;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;

with GNATdoc.Comments.RST_Helpers;
with GNATdoc.Configuration;
with GNATdoc.Entities; use GNATdoc.Entities;
with Streams;

package body GNATdoc.Backend.RST is

   function Documentation_File_Name
     (Entity : Entity_Information) return VSS.Strings.Virtual_String;

   procedure Generate_Documentation
     (Self   : in out RST_Backend_Base'Class;
      Entity : Entity_Information);
   --  Generate RTS file for given entity.

   function "*"
     (Count : VSS.Strings.Character_Count;
      Item  : VSS.Characters.Virtual_Character)
      return VSS.Strings.Virtual_String;

   ---------
   -- "*" --
   ---------

   function "*"
     (Count : VSS.Strings.Character_Count;
      Item  : VSS.Characters.Virtual_Character)
      return VSS.Strings.Virtual_String is
   begin
      return Result : VSS.Strings.Virtual_String do
         for J in 1 .. Count loop
            Result.Append (Item);
         end loop;
      end return;
   end "*";

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
      Name    : constant GNATCOLL.VFS.Virtual_File :=
        GNATCOLL.VFS.Create_From_Base
          (GNATCOLL.VFS.Filesystem_String
             (VSS.Strings.Conversions.To_UTF_8_String
                (Documentation_File_Name (Entity))),
           GNATdoc.Configuration.Provider.Output_Directory
             (Self.Name).Full_Name);

      File    : Streams.Output_Text_Stream;
      Success : Boolean := True;

      procedure Generate_Subprogram_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String);
      --  Generate documentation for the given subprogram.

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
              (Indent & "    ", Entity.Documentation, Self.Pass_Through),
            Success);
         File.New_Line (Success);
      end Generate_Subprogram_Documentation;

   begin
      File.Open (Name);

      File.Put (Entity.Qualified_Name.Character_Length * '*', Success);
      File.New_Line (Success);
      File.Put (Entity.Qualified_Name, Success);
      File.New_Line (Success);
      File.Put (Entity.Qualified_Name.Character_Length * '*', Success);
      File.New_Line (Success);

      File.Put (".. ada:set_package:: ", Success);
      File.Put (Entity.Qualified_Name, Success);
      File.New_Line (Success);
      File.New_Line (Success);

      File.Put_Lines
        (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
           ("", Entity.Documentation, Self.Pass_Through),
         Success);
      File.New_Line (Success);

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
                    ("    ", Item.Documentation, Self.Pass_Through),
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
                           GNATdoc.Entities.To_Entity (Method.Signature).all,
                           Entity.Qualified_Name);
                     end loop;
                  end;
               end if;

               File.New_Line (Success);
            end loop;
         end if;
      end;

      begin
         declare
            Subprograms : GNATdoc.Entities.Entity_Information_Sets.Set;

         begin
            for Subprogram of Entity.Subprograms loop
               if not Self.OOP_Mode and then not Subprogram.Is_Method then
                  Subprograms.Insert (Subprogram);
               end if;
            end loop;

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

end GNATdoc.Backend.RST;
