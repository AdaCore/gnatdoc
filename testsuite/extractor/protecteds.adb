
--  This package contains test cases of documentation extraction for protected
--  bodies. Coverage of tests of procedures/functions/entries are limited to
--  few cases only (this code is tested by subprograms tests).

package body Protecteds is

--   type IE is synchronized interface;
--
--   type IP is synchronized interface;
--
--   not overriding procedure Process (Self : IP) is abstract;

   --  Leading description of the protected body P_Leading.
   protected body P_Leading is
   end P_Leading;

   protected body P_Intermediate is
      --  Intermediate description of the protected body P_Intermediate.
   end P_Intermediate;

   --  Leading description of the protected type PT_Leading.
   protected body PT_Leading is
   end PT_Leading;

   protected body PT_Intermediate is
      --  Intermediate description of the protected type PT_Intermediate.
   end PT_Intermediate;

   protected body PT_Discriminant_Component_Short is
   end PT_Discriminant_Component_Short;

   protected body PT_Discriminant_Component_Longer is
   end PT_Discriminant_Component_Longer;

   protected body PT_Discriminant_Longer is
   end PT_Discriminant_Longer;

   protected body P_Private_Components_Subprograms is
      --  Protected type declaration with mix of components/subprograms in private part.

      procedure P is null;
      --  Description of the procedure P body

      function F return Integer is (0);
      --  Description of the function F body

      entry E when False is
         --  Description of the entry E body
      begin
         null;
      end E;

   end P_Private_Components_Subprograms;

end Protecteds;
