with Discriminant_Record_Types; use Discriminant_Record_Types;

package body Discriminant_Record_Types_Package is

   procedure Dummy is
   begin
      declare
         Object : Discriminant_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;

      declare
         Object : Known_Discriminant_Private_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;

      declare
         Object : Incomplete_Discriminant_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;

      declare
         Object : Incomplete_Known_Discriminant_Private_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;
   end Dummy;

end Discriminant_Record_Types_Package;