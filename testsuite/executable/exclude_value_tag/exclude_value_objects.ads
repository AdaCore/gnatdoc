--  Test for `@exclude-value` tag functionality
--
--  This module demonstrates the `@exclude-value` tag which suppresses
--  the output of :defval: fields for constants and variables in RST-PT backend.

package Exclude_Value_Objects is

   Test_Constant_1 : constant Integer := 42;
   --  This constant has a default value but it will not be shown
   --  @exclude-value

   Test_Constant_2 : constant Integer := 100;
   --  This constant has a default value and will be shown normally

   Test_Variable_1 : Integer := 50;
   --  This variable has a default value but it will not be shown
   --  @exclude-value

   Test_Variable_2 : Integer := 200;
   --  This variable has a default value and will be shown normally

end Exclude_Value_Objects;
