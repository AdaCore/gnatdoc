
package Synthetics is

   type Implicit_Record is null record;
   --  Description of the type with implicit equality operator.
   --  LAL 20250923: not supported

   type Derived_Implicit_Record is new Implicit_Record;

   type Explicit_Record is null record;

   function "="
     (Left : Explicit_Record; Right : Explicit_Record) return Boolean;
   --  Public declaration of the explicit equal check operator

   type Derived_Explicit_Record is new Explicit_Record;

   type Integer_32 is range -(2 **31) .. +(2 **31 - 1);

   type Derived_Integer_32 is new Integer_32;

   type Unsigned_32 is mod 2 ** 32;

   type Derived_Unsigned_32 is new Unsigned_32;

   type Integer_32_Array is array (Positive range <>) of Integer_32;

   type Derived_Integer_32_Array is new Integer_32_Array;

private

   function "="
     (Left  : Explicit_Record;
      Right : Explicit_Record) return Boolean is (False);
   --  Private declaration of the explicit equal check operator

   procedure Dummy;

end Synthetics;
