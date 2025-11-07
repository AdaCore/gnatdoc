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

with VSS.Strings.Conversions;

with GNATdoc.Comments.RST_Helpers;
with GNATdoc.Configuration;
with Streams;

package body GNATdoc.Backend.RST.PT is

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
   --  Include `Items` when they are not private

   procedure Union
     (Container : in out Entity_Information_Sets.Set;
      Items     : GNATdoc.Entities.Entity_Reference_Sets.Set);
   --  Include `Items` when they are not private

   procedure Generate_Documentation
     (Self   : in out PT_RST_Backend'Class;
      Entity : GNATdoc.Entities.Entity_Information);
   --  Generate RTS file for given entity.

   --------------
   -- Generate --
   --------------

   overriding procedure Generate (Self : in out PT_RST_Backend) is
   begin
      for Item of GNATdoc.Entities.Globals.Packages loop
         if not Is_Private_Entity (Item) then
            Self.Generate_Documentation (Item.all);
         end if;
      end loop;
   end Generate;

   ----------------------------
   -- Generate_Documentation --
   ----------------------------

   procedure Generate_Documentation
     (Self   : in out PT_RST_Backend'Class;
      Entity : GNATdoc.Entities.Entity_Information)
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

      procedure Generate_Type_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String);
      --  Generate documentation for type entity

      procedure Generate_Object_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String;
         Inside_Type  : Boolean);
      --  Generate documentation for object entity.

      procedure Generate_Exception_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String);
      --  Generate documentation for exception entity.

      procedure Generate_Callable_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String);
      --  Generate documentation for the given callable entity.

      -------------------------------------
      -- Generate_Callable_Documentation --
      -------------------------------------

      procedure Generate_Callable_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String)
      is
         use type VSS.Strings.Virtual_String;

      begin
         File.New_Line (Success);

         case Entity.Kind is
            when GNATdoc.Entities.Ada_Function =>
               File.Put (Indent, Success);
               File.Put (".. ada:function:: ", Success);

            when GNATdoc.Entities.Ada_Procedure =>
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
               Pass_Through  => True,
               Code_Snippet  => False),
            Success);

         File.New_Line (Success);
      end Generate_Callable_Documentation;

      --------------------------------------
      -- Generate_Exception_Documentation --
      --------------------------------------

      procedure Generate_Exception_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String)
      is
         use type VSS.Strings.Virtual_String;

      begin
         File.New_Line (Success);

         File.Put (Indent, Success);
         File.Put (".. ada:exception:: ", Success);

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
               Pass_Through  => True,
               Code_Snippet  => False),
            Success);
         File.New_Line (Success);
      end Generate_Exception_Documentation;

      -----------------------------------
      -- Generate_Object_Documentation --
      -----------------------------------

      procedure Generate_Object_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String;
         Inside_Type  : Boolean)
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

         if not Inside_Type and not Entity.RSTPT_Objtype.Is_Empty then
            File.Put (Indent, Success);
            File.Put ("    :objtype: ", Success);
            File.Put (Entity.RSTPT_Objtype, Success);
            File.New_Line (Success);
         end if;

         --  XXX `:defval:` are not supported
         File.New_Line (Success);

         File.Put_Lines
           (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
              (Indent        => Indent & "    ",
               Documentation => Entity.Documentation,
               Pass_Through  => True,
               Code_Snippet  => False),
            Success);
         File.New_Line (Success);
      end Generate_Object_Documentation;

      ---------------------------------
      -- Generate_Type_Documentation --
      ---------------------------------

      procedure Generate_Type_Documentation
        (Indent       : VSS.Strings.Virtual_String;
         Entity       : GNATdoc.Entities.Entity_Information;
         Package_Name : VSS.Strings.Virtual_String)
      is
         use type VSS.Strings.Virtual_String;

         Constants : Entity_Information_Sets.Set;
         Methods   : Entity_Information_Sets.Set;

      begin
         File.Put (".. ada:type:: type ", Success);
         File.Put (Entity.Name, Success);
         File.New_Line (Success);
         File.Put ("    :package: ", Success);
         File.Put (Package_Name, Success);
         File.New_Line (Success);
         File.New_Line (Success);

         File.Put_Lines
           (GNATdoc.Comments.RST_Helpers.Get_RST_Documentation
              (Indent        => Indent & "    ",
               Documentation => Entity.Documentation,
               Pass_Through  => True,
               Code_Snippet  => True),
            Success);

         Constants.Clear;
         Methods.Clear;

         for Object of Entity.Belongs_Constants loop
            if not Is_Private_Entity
              (GNATdoc.Entities.To_Entity (Object.Signature))
            then
               Constants.Insert
                 (GNATdoc.Entities.To_Entity (Object.Signature));
            end if;
         end loop;

         for Object of Constants loop
            Generate_Object_Documentation
              ("    ", Object.all, Entity.Qualified_Name, True);
         end loop;

         for Method of Entity.Belongs_Subprograms loop
            if not Is_Private_Entity
              (GNATdoc.Entities.To_Entity (Method.Signature))
            then
               Methods.Insert
                 (GNATdoc.Entities.To_Entity (Method.Signature));
            end if;
         end loop;

         for Method of Methods loop
            Generate_Callable_Documentation
              ("    ", Method.all, Entity.Qualified_Name);
         end loop;

         File.New_Line (Success);
      end Generate_Type_Documentation;

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
            Pass_Through  => True,
            Code_Snippet  => True),
         Success);
      File.New_Line (Success);

      declare
         Entities : Entity_Information_Sets.Set;

      begin
         Union (Entities, Entity.Simple_Types);
         Union (Entities, Entity.Array_Types);
         Union (Entities, Entity.Record_Types);
         Union (Entities, Entity.Interface_Types);
         Union (Entities, Entity.Tagged_Types);
         Union (Entities, Entity.Task_Types);
         Union (Entities, Entity.Protected_Types);
         Union (Entities, Entity.Access_Types);
         Union (Entities, Entity.Subtypes);
         Union (Entities, Entity.Belongs_Constants);
         Union (Entities, Entity.Variables);
         Union (Entities, Entity.Exceptions);
         Union (Entities, Entity.Belongs_Subprograms);

         for Item of Entities loop
            case Item.Kind is
               when GNATdoc.Entities.Ada_Function
                  | GNATdoc.Entities.Ada_Procedure
               =>
                  Generate_Callable_Documentation
                    ("", Item.all, Entity.Qualified_Name);

               when GNATdoc.Entities.Ada_Exception =>
                  Generate_Exception_Documentation
                    ("", Item.all, Entity.Qualified_Name);

               when GNATdoc.Entities.Ada_Object =>
                  Generate_Object_Documentation
                    ("", Item.all, Entity.Qualified_Name, False);

               when GNATdoc.Entities.Ada_Interface_Type
                  | GNATdoc.Entities.Ada_Other_Type
                  | GNATdoc.Entities.Ada_Tagged_Type
               =>
                  Generate_Type_Documentation
                    ("", Item.all, Entity.Qualified_Name);

               when others =>
                  raise Program_Error
                    with GNATdoc.Entities.Entity_Kind'Image (Item.Kind)
                    & " "
                    & VSS.Strings.Conversions.To_UTF_8_String
                    (Item.Qualified_Name);
            end case;
         end loop;
      end;

      File.Close;
   end Generate_Documentation;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out PT_RST_Backend) is
   begin
      RST_Backend_Base (Self).Initialize;

      Self.OOP_Mode           := True;
      Self.Alphabetical_Order := False;
   end Initialize;

   ----------
   -- Less --
   ----------

   function Less
     (Left  : not null GNATdoc.Entities.Entity_Information_Access;
      Right : not null GNATdoc.Entities.Entity_Information_Access)
            return Boolean
   is
      use type VSS.Strings.Character_Count;
      use type VSS.Strings.Line_Count;
      use type VSS.Strings.Virtual_String;

   begin
      if Left.Location.File < Right.Location.File then
         return True;

      elsif Left.Location.File = Right.Location.File
        and Left.Location.Line < Right.Location.Line
      then
         return True;

      elsif Left.Location.File = Right.Location.File
        and Left.Location.Line < Right.Location.Line
        and Left.Location.Column < Right.Location.Column
      then
         return True;

      else
         return False;
      end if;
   end Less;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out PT_RST_Backend) return VSS.Strings.Virtual_String is
   begin
      return "rstpt";
   end Name;

   -----------
   -- Union --
   -----------

   procedure Union
     (Container : in out Entity_Information_Sets.Set;
      Items     : GNATdoc.Entities.Entity_Information_Sets.Set) is
   begin
      for Item of Items loop
         if not Is_Private_Entity (Item) then
            Container.Insert (Item);
         end if;
      end loop;
   end Union;

   -----------
   -- Union --
   -----------

   procedure Union
     (Container : in out Entity_Information_Sets.Set;
      Items     : GNATdoc.Entities.Entity_Reference_Sets.Set) is
   begin
      for Item of Items loop
         if not Is_Private_Entity
           (GNATdoc.Entities.To_Entity (Item.Signature))
         then
            Container.Insert (GNATdoc.Entities.To_Entity (Item.Signature));
         end if;
      end loop;
   end Union;

end GNATdoc.Backend.RST.PT;
