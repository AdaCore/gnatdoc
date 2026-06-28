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
     (Type_Decl_Node  : Libadalang.Analysis.Type_Expr'Class;
      Profile_Renderer : Subprogram_Profile_Access := null)
      return VSS.Strings.Virtual_String is
   begin
      case Type_Decl_Node.Kind is
         when Ada_Anonymous_Type =>
            declare
               Type_Def_Node : constant Type_Def :=
                 Type_Decl_Node.As_Anonymous_Type.F_Type_Decl.F_Type_Def;

            begin
               case Type_Def_Node.Kind is
                  when Ada_Type_Access_Def =>
                     declare
                        Name : constant Defining_Name :=
                          Type_Def_Node.As_Type_Access_Def
                            .F_Subtype_Indication.F_Name
                              .P_Referenced_Defining_Name;

                     begin
                        return
                          (if Name.Is_Null
                           then ""
                           else VSS.Strings.To_Virtual_String
                             (Name.P_Fully_Qualified_Name));
                     end;

                  when Ada_Access_To_Subp_Def =>
                     return Result : VSS.Strings.Virtual_String :=
                       (if Type_Def_Node.As_Access_To_Subp_Def.F_Has_Not_Null
                          then "not null access "
                          else "access ")
                     do
                        if Profile_Renderer = null then
                           Result.Append
                             (VSS.Strings.To_Virtual_String
                                (Type_Def_Node.As_Access_To_Subp_Def
                                   .F_Subp_Spec.Text));
                        else
                           Result.Append
                             (Profile_Renderer.all
                                (Type_Def_Node.As_Access_To_Subp_Def
                                   .F_Subp_Spec));
                        end if;
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
            declare
               Name : constant Defining_Name :=
                 Type_Decl_Node.As_Subtype_Indication.F_Name
                   .P_Referenced_Defining_Name;

            begin
               return Result : VSS.Strings.Virtual_String :=
                 (if Name.Is_Null
                  then ""
                  else VSS.Strings.To_Virtual_String
                    (Name.P_Fully_Qualified_Name))
               do
                  if Type_Decl_Node.As_Subtype_Indication.F_Name.Kind
                    = Ada_Attribute_Ref
                  then
                     Result.Append (''');
                     Result.Append
                       (VSS.Strings.To_Virtual_String
                          (Type_Decl_Node.As_Subtype_Indication.F_Name
                             .As_Attribute_Ref.F_Attribute.Text));
                  end if;
               end return;
            end;

         when others =>
            raise Program_Error;
            --  Should not happened.
      end case;
   end RST_Type_Name;

end GNATdoc.RST_Utilities;