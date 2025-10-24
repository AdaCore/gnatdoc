
package Objects is

   Named_Number : constant := 2;
   --  Description of the named number

   Public_Constant : constant Integer := 3;
   --  Description of the `Public_Constant`

   Private_Constant : constant Integer;
   --  Public description of the `Private_Constant`

   Value : Integer;
   --  Description of the object

   Value_Default : Integer := 1;
   --  Description of the object with default value

private

   Private_Constant : constant Integer := 4;
   --  Private description of the `Private_Constant`

   procedure Dummy;

end Objects;
