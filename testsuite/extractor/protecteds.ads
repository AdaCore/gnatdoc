
--  This package contains test cases of documentation extraction for protected
--  types. Coverage of tests of procedures/functions/entries are limited to few
--  cases only (this code is tested by subprograms tests).

package Protecteds is

   type IE is synchronized interface;

   type IP is synchronized interface;

   not overriding procedure Process (Self : IP) is abstract;

   --  Leading description of the protected type P_Leading.
   protected P_Leading is
   end P_Leading;

   protected P_Intermediate is
      --  Intermediate description of the protected type P_Intermediate.
   end P_Intermediate;

   --  Leading description of the protected type PT_Leading.
   protected type PT_Leading is
   end PT_Leading;

   protected type PT_Intermediate is
      --  Intermediate description of the protected type PT_Intermediate.
   end PT_Intermediate;

end Protecteds;
