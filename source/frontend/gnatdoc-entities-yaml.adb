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

with VSS.String_Vectors;
with VSS.Characters;
with VSS.Strings.Cursors;
with VSS.Strings.Character_Iterators;
with VSS.Characters.Latin;

with GNATdoc.Comments.Helpers;

package body GNATdoc.Entities.YAML is

   procedure Add_Info (Result    : in out VSS.Strings.Virtual_String;
                       Entity    :        Entity_Information;
                       Indent    :        VSS.Strings.Virtual_String := "";
                       Recursive :        Boolean := True);

   function To_YAML (B : Boolean) return VSS.Strings.Virtual_String
   is (if B then VSS.Strings.To_Virtual_String ("true") else "false");

   function YAML_String_Escape (Str : VSS.Strings.Virtual_String)
                                return VSS.Strings.Virtual_String;
   function To_YAML_String (Vect : VSS.String_Vectors.Virtual_String_Vector)
                            return VSS.Strings.Virtual_String;
   function To_YAML_String (Str : VSS.Strings.Virtual_String)
                            return VSS.Strings.Virtual_String;

   ------------------------
   -- YAML_String_Escape --
   ------------------------

   function YAML_String_Escape (Str : VSS.Strings.Virtual_String)
                                return VSS.Strings.Virtual_String
   is
      use VSS.Strings;
      use VSS.Characters;
      use VSS.Strings.Character_Iterators;

      Result : VSS.Strings.Virtual_String := Str;
      J : Character_Iterator := Result.Before_First_Character;
      C : Virtual_Character;
   begin

      while J.Forward loop
         C := J.Element;

         if C = '"' or else C = '\' then
            Insert (Result,
                    VSS.Strings.Cursors.Abstract_Cursor (J),
                    '\');
         end if;
      end loop;

      return Result;
   end YAML_String_Escape;

   --------------------
   -- To_YAML_String --
   --------------------

   function To_YAML_String (Vect : VSS.String_Vectors.Virtual_String_Vector)
                            return VSS.Strings.Virtual_String
   is
      use VSS.Strings;

      Result : VSS.Strings.Virtual_String;

      First : Boolean := True;
   begin
      Append (Result, """");
      for Line of Vect loop
         if not First then
            Append (Result, "\n");
         else
            First := False;
         end if;

         Append (Result, YAML_String_Escape (Line));
      end loop;
      Append (Result, """");
      return Result;
   end To_YAML_String;

   --------------------
   -- To_YAML_String --
   --------------------

   function To_YAML_String (Str : VSS.Strings.Virtual_String)
                            return VSS.Strings.Virtual_String
   is
      use VSS.Strings;
   begin
      return """" & YAML_String_Escape (Str) & """";
   end To_YAML_String;

   --------------
   -- Add_Info --
   --------------

   procedure Add_Info (Result    : in out VSS.Strings.Virtual_String;
                       Entity    :        Entity_Information;
                       Indent    :        VSS.Strings.Virtual_String := "";
                       Recursive :        Boolean := True)
   is
      use VSS.Strings;

      procedure Add (Str : VSS.Strings.Virtual_String);
      procedure Add_Line (Line : VSS.Strings.Virtual_String);
      procedure Add_Sub (Id  : VSS.Strings.Virtual_String;
                         Set : Entity_Information_Sets.Set);

      ---------
      -- Add --
      ---------

      procedure Add (Str : VSS.Strings.Virtual_String) is
      begin
         Append (Result, Str);
      end Add;

      --------------
      -- Add_Line --
      --------------

      procedure Add_Line (Line : VSS.Strings.Virtual_String) is
      begin
         Append (Result, Indent);
         Append (Result, Line);
         Append (Result, VSS.Characters.Latin.Line_Feed);
      end Add_Line;

      -------------
      -- Add_Sub --
      -------------

      procedure Add_Sub (Id  : VSS.Strings.Virtual_String;
                         Set : Entity_Information_Sets.Set)
      is
      begin
         if not Set.Is_Empty then
            Add (Id & ": " & To_YAML (Set, Indent & "   ", Recursive) & ",");
         end if;
      end Add_Sub;

   begin
      Add_Line ("{");
      Add_Line ("name: " & To_YAML_String (Entity.Name) & ",");
      Add_Line ("qualified_name: " & To_YAML_String
                (Entity.Qualified_Name) & ",");
      Add_Line ("signature: " & To_YAML_String (Entity.Signature) & ",");
      Add_Line ("enclosing: " & To_YAML_String (Entity.Enclosing) & ",");
      Add_Line ("is_private: " & To_YAML (Entity.Is_Private) & ",");

      Add_Line ("documentation: " & To_YAML_String
                (GNATdoc.Comments.Helpers.Get_Plain_Text_Description
                   (Entity.Documentation)) & ",");
      Add_Line ("documentation_snippet: " & To_YAML_String
                (GNATdoc.Comments.Helpers.Get_Ada_Code_Snippet
                   (Entity.Documentation)) & ",");

      if Recursive then
         Add_Sub (To_Virtual_String ("packages"), Entity.Packages);
         Add_Sub (To_Virtual_String ("simple_types"), Entity.Simple_Types);
         Add_Sub (To_Virtual_String ("array_types"), Entity.Array_Types);
         Add_Sub (To_Virtual_String ("record_types"), Entity.Record_Types);
         Add_Sub (To_Virtual_String ("interface_types"),
                  Entity.Interface_Types);
         Add_Sub (To_Virtual_String ("tagged_types"), Entity.Tagged_Types);
         Add_Sub (To_Virtual_String ("access_types"), Entity.Access_Types);
         Add_Sub (To_Virtual_String ("subtypes"), Entity.Subtypes);
         Add_Sub (To_Virtual_String ("constants"), Entity.Constants);
         Add_Sub (To_Virtual_String ("variables"), Entity.Variables);
      end if;
      Append (Result, Indent & "}");
   end Add_Info;

   -------------
   -- To_YAML --
   -------------

   function To_YAML (Entity    : Entity_Information;
                     Indent    : VSS.Strings.Virtual_String := "";
                     Recursive : Boolean := True)
                     return VSS.Strings.Virtual_String
   is
      Result : VSS.Strings.Virtual_String;
   begin
      Add_Info (Result, Entity, Indent, Recursive);
      return Result;
   end To_YAML;

   -------------
   -- To_YAML --
   -------------

   function To_YAML (Set    : Entity_Information_Sets.Set;
                     Indent : VSS.Strings.Virtual_String := "";
                     Recursive : Boolean := True)
                     return VSS.Strings.Virtual_String
   is
      use VSS.Strings;

      procedure Add_Line (Line : VSS.Strings.Virtual_String);

      Result : VSS.Strings.Virtual_String;

      --------------
      -- Add_Line --
      --------------

      procedure Add_Line (Line : VSS.Strings.Virtual_String) is
      begin
         Append (Result, Indent);
         Append (Result, Line);
         Append (Result, VSS.Characters.Latin.Line_Feed);
      end Add_Line;

   begin
      Add_Line ("[");
      for E of Set loop
         Add_Info (Result, E.all, Indent & "    ", Recursive);
         Add_Line (",");
      end loop;
      Add_Line ("]");
      return Result;
   end To_YAML;

end GNATdoc.Entities.YAML;
