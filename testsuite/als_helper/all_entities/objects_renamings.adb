
package body Objects_Renamings is

   procedure Dummy is
   begin
      declare
         V : Integer := Renamed_Named_Number;

      begin
         null;
      end;

      declare
         V : Integer := Renamed_Public_Constant;

      begin
         null;
      end;

      declare
         V : Integer := Renamed_Private_Constant;

      begin
         null;
      end;

      declare
         V : Integer := Renamed_Value;

      begin
         null;
      end;
   end Dummy;

end Objects_Renamings;
