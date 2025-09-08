
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

   protected type PT_Discriminant_Component_Short
    (Discriminant : Integer)  --  Short description of the discriminant
   is
   private
      Component : Float;  --  Short description of the component
   end PT_Discriminant_Component_Short;

   protected type PT_Discriminant_Component_Longer
    (Discriminant : Integer)
     --  Longer description of the discriminant
   is
   private
      Component : Float;
      --  Longer description of the component
   end PT_Discriminant_Component_Longer;

   protected type PT_Discriminant_Longer
    (Discriminant : Integer)
     --  Longer description of the discriminant
   is
   end PT_Discriminant_Longer;

   protected P_Private_Components_Subprograms is
      --  Protected type declaration with mix of components/subprograms in private part.

   private

      X : Integer;
      --  Description of the component X

      procedure P;
      --  Description of the procedure P

      Y : Integer;
      --  Description of the component Y

      function F return Integer;
      --  Description of the function F

      Z : Integer;
      --  Description of the component Z

      entry E;
      --  Description of the entry E

   end P_Private_Components_Subprograms;

   protected P_Entry_Family is
      --  Protected object with entry family.

      entry E1 (Positive range 1 .. 10) (X : Float);
      --  First entry family.

      entry E2 (Positive range 1 .. 10) (X : Float)
        with SPARK_Mode => Off;
      --  Second entry family.
   end P_Entry_Family;

private

   protected type GNATdoc_135 is
      --  Protected type is declared in the private part of the package
      --  specification.
   end GNATdoc_135;

end Protecteds;
