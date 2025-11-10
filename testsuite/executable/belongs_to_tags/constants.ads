
package Constants is

   type TT is tagged limited null record;

   CT : constant TT := (others => <>);

   BT : constant TT := (others => <>);
   --  @belongs-to TT

   type TI is range 0 ..  100;

   CI : constant TI := 5;

   BI : constant TI := 10;
   --  @belongs-to TI

end Constants;
