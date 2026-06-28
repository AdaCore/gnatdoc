------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2026, AdaCore                        --
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

with Libadalang.Common;

package body GNATdoc.RST_Utilities is

   use Libadalang.Analysis;
   use Libadalang.Common;

   -------------------
   -- RST_Type_Name --
   -------------------

   function RST_Type_Name
     (Type_Decl_Node : Libadalang.Analysis.Type_Expr'Class)
      return VSS.Strings.Virtual_String is
      function Normalized_Subtype_Name
        (Subtype_Node : Libadalang.Analysis.Subtype_Indication'Class)
         return VSS.Strings.Virtual_String;

      -----------------------------
      -- Normalized_Subtype_Name --
      -----------------------------

      function Normalized_Subtype_Name
        (Subtype_Node : Libadalang.Analysis.Subtype_Indication'Class)
         return VSS.Strings.Virtual_String
      is
         Name : constant Defining_Name :=
           Subtype_Node.F_Name.P_Referenced_Defining_Name;

      begin
         return Result : VSS.Strings.Virtual_String :=
           (if Name.Is_Null
            then ""
            else VSS.Strings.To_Virtual_String (Name.P_Fully_Qualified_Name))
         do
            if Subtype_Node.F_Name.Kind = Ada_Attribute_Ref then
               Result.Append (''');
               Result.Append
                 (VSS.Strings.To_Virtual_String
                    (Subtype_Node.F_Name.As_Attribute_Ref.F_Attribute.Text));
            end if;
         end return;
      end Normalized_Subtype_Name;

   begin
      case Type_Decl_Node.Kind is
         when Ada_Anonymous_Type =>
            declare
               Type_Def_Node : constant Type_Def :=
                 Type_Decl_Node.As_Anonymous_Type.F_Type_Decl.F_Type_Def;

            begin
               case Type_Def_Node.Kind is
                  when Ada_Type_Access_Def =>
                     return Result : VSS.Strings.Virtual_String :=
                       "access "
                     do
                        Result.Append
                          (Normalized_Subtype_Name
                             (Type_Def_Node.As_Type_Access_Def
                                .F_Subtype_Indication));
                     end return;

                  when Ada_Access_To_Subp_Def =>
                     return Result : VSS.Strings.Virtual_String :=
                       (if Type_Def_Node.As_Access_To_Subp_Def.F_Has_Not_Null
                          then "not null access "
                          else "access ")
                     do
                        Result.Append
                          (RST_Profile
                             (Type_Def_Node.As_Access_To_Subp_Def
                                .F_Subp_Spec));
                     end return;

                  when Ada_Array_Type_Def =>
                     return
                       VSS.Strings.To_Virtual_String (Type_Def_Node.Text);

                  when others =>
                     raise Program_Error;
                     --  Should not happened.
               end case;
            end;

         when Ada_Subtype_Indication =>
            return
              Normalized_Subtype_Name (Type_Decl_Node.As_Subtype_Indication);

         when others =>
            raise Program_Error;
            --  Should not happened.
      end case;
   end RST_Type_Name;

   -----------------
   -- RST_Profile --
   -----------------

   function RST_Profile
     (Node : Libadalang.Analysis.Subp_Spec'Class)
      return VSS.Strings.Virtual_String
   is
      Params : constant Libadalang.Analysis.Params'Class :=
        Node.F_Subp_Params;
      First  : Boolean := True;

   begin
      return Result : VSS.Strings.Virtual_String do
         case Node.F_Subp_Kind is
            when Ada_Subp_Kind_Function =>
               Result.Append ("function");
            when Ada_Subp_Kind_Procedure =>
               Result.Append ("procedure");
         end case;

         if not Node.F_Subp_Name.Is_Null then
            Result.Append (' ');
            Result.Append
              (VSS.Strings.To_Virtual_String (Node.F_Subp_Name.Text));
         end if;

         if not Params.Is_Null then
            Result.Append (" (");

            for Param of Params.F_Params loop
               declare
                  Ids       : constant Defining_Name_List := Param.F_Ids;
                  Type_Name : constant VSS.Strings.Virtual_String :=
                    RST_Type_Name (Param.F_Type_Expr);

               begin
                  for Id of Ids loop
                     if First then
                         First := False;

                     else
                        Result.Append ("; ");
                     end if;

                     Result.Append
                       (VSS.Strings.To_Virtual_String (Id.F_Name.Text));
                     Result.Append (" : ");
                     Result.Append (Type_Name);
                  end loop;
               end;
            end loop;

            Result.Append (")");
         end if;

         if Node.F_Subp_Kind = Ada_Subp_Kind_Function
           and then not Node.F_Subp_Returns.Is_Null
         then
            Result.Append (" return ");
            Result.Append (RST_Type_Name (Node.F_Subp_Returns));
         end if;
      end return;
   end RST_Profile;

end GNATdoc.RST_Utilities;