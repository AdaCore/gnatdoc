
with Objects;
with Objects_Renamings;

package body Objects_Package is

   procedure Dummy is
   begin
      declare
         Object : Integer := Objects.Named_Number;

      begin
         null;
      end;

      declare
         Object : Integer := Objects.Public_Constant;

      begin
         null;
      end;

      declare
         Object : Integer := Objects.Private_Constant;

      begin
         null;
      end;

      declare
         Object : Integer := Objects.Value;

      begin
         null;
      end;

      declare
         Object : Integer := Objects.Value_Default;

      begin
         null;
      end;

      --  Renamings

      declare
         V : Integer := Objects_Renamings.Renamed_Named_Number;

      begin
         null;
      end;

      declare
         V : Integer := Objects_Renamings.Renamed_Public_Constant;

      begin
         null;
      end;

      declare
         V : Integer := Objects_Renamings.Renamed_Private_Constant;

      begin
         null;
      end;

      declare
         V : Integer := Objects_Renamings.Renamed_Value;

      begin
         null;
      end;
   end Dummy;

end Objects_Package;
