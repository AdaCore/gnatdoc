
package body Record_Types is

   procedure Dummy is
   begin
      declare
         Object : Discriminant_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;

      declare
         Object : Unknown_Discriminant_Private_Null_Record (1);
         Value  : Integer;

      begin
         Value := Object.Discriminant;
      end;
   end Dummy;

end Record_Types;