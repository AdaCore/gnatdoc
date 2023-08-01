
--  Test of documentation extraction for the simple types:
--    - signed integer
--    - modular
--    - floating point
--    - ordinary fixed point
--    - decimal fixed point

package Simple_Types is

   type Integer_Type is range -100 .. 100;
   --  Description of the signed integer type

   type Modular_Type is mod 2**16;
   --  Description of the modular type

   type Float_Type is digits 10;
   --  Description of the floating point type

   type Fixed_Type is delta 0.001 range 0.0 .. 1.0;
   --  Description of the ordinary fixed point type

   type Decimal_Type is delta 0.01 digits 7;
   --  Description of the decimal fixed point type

end Simple_Types;
