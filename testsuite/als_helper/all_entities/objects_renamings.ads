
with Objects;

package Objects_Renamings is

   Renamed_Named_Number : constant := Objects.Named_Number;
   --  Description of the renamed named number

   Renamed_Public_Constant : Integer renames Objects.Public_Constant;
   --  Description of the renamed `Public_Constant`

   Renamed_Private_Constant : Integer renames Objects.Private_Constant;
   --  Description of the renamed `Private_Constant`

   Renamed_Value : Integer renames Objects.Value;
   --  Description of the renamed object

private

   procedure Dummy;

end Objects_Renamings;
