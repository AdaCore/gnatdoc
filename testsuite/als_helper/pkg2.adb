with Record_Types;

package body Pkg2 is

   procedure Dummy is
   begin
      declare
         Object : Record_Types.Discriminant_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;

      declare
         Object : Record_Types.Known_Discriminant_Private_Null_Record (2);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;
   end Dummy;

end Pkg2;
