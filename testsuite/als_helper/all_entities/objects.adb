
package body Objects is

   procedure Dummy is
   begin
      declare
         Object : Integer := Named_Number;

      begin
         null;
      end;

      declare
         Object : Integer := Public_Constant;

      begin
         null;
      end;

      declare
         Object : Integer := Private_Constant;

      begin
         null;
      end;

      declare
         Object : Integer := Value;

      begin
         null;
      end;

      declare
         Object : Integer := Value_Default;

      begin
         null;
      end;
   end Dummy;

end Objects;
