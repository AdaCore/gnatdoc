
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

   type Tagged_Default is tagged private;
   --  Tagged type with default `"="`

   type Derived_Tagged_Default is new Tagged_Default with private;
   --  Derived type with derived `"="`

   type Derived_Tagged_Default_Public is new Tagged_Default with private;
   --  Derived type with redefined `"="` in public part

   function "="
     (Left  : Derived_Tagged_Default_Public;
      Right : Derived_Tagged_Default_Public) return Boolean;
   --  Public description of `"="` of `Derived_Tagged_Default_Public`

   type Derived_Tagged_Default_Private is new Tagged_Default with private;
   --  Derived type with redefined `"="` in private part

   type Tagged_Public is tagged private;
   --  Tagged type with `"="` declared in public part

   function "="
     (Left  : Tagged_Public;
      Right : Tagged_Public) return Boolean;
   --  Public description of `"="` of `Tagged_Public`

   type Derived_Tagged_Public is new Tagged_Public with private;
   --  Derived type with derived `"="`

   type Derived_Tagged_Public_Public is new Tagged_Public with private;
   --  Derived type with redefined `"="` in public part

   function "="
     (Left  : Derived_Tagged_Public_Public;
      Right : Derived_Tagged_Public_Public) return Boolean;
   --  Public description of `"="` of `Derived_Tagged_Public_Public`

   type Derived_Tagged_Public_Private is new Tagged_Public with private;
   --  Derived type with redefined `"="` in private part

   type Tagged_Private is tagged private;
   --  Tagged type with `"="` declared in private part

   type Derived_Tagged_Private is new Tagged_Private with private;
   --  Derived type with derived `"="`

   type Derived_Tagged_Private_Public is new Tagged_Private with private;
   --  Derived type with redefined `"="` in public part

   function "="
     (Left  : Derived_Tagged_Private_Public;
      Right : Derived_Tagged_Private_Public) return Boolean;
   --  Public description of `"="` of `Derived_Tagged_Private_Public`

   type Derived_Tagged_Private_Private is new Tagged_Private with private;
   --  Derived type with redefined `"="` in private part

private

   type Tagged_Default is tagged null record;

   type Derived_Tagged_Default is new Tagged_Default with null record;

   type Derived_Tagged_Default_Private is new Tagged_Default with null record;

   function "="
     (Left  : Derived_Tagged_Default_Private;
      Right : Derived_Tagged_Default_Private) return Boolean is (False);
   --  Private description of `"="` of `Derived_Tagged_Default_Private`

   type Derived_Tagged_Default_Public is new Tagged_Default with null record;

   type Tagged_Public is tagged null record;
   --  Tagged type with `"="` declared in public part

   type Derived_Tagged_Public is new Tagged_Public with null record;

   type Derived_Tagged_Public_Public is new Tagged_Public with null record;

   type Derived_Tagged_Public_Private is new Tagged_Public with null record;
   --  Derived type with redefined `"="` in private part

   function "="
     (Left  : Derived_Tagged_Public_Private;
      Right : Derived_Tagged_Public_Private) return Boolean is (False);
   --  Private description of `"="` of `Derived_Tagged_Public_Private`

   type Tagged_Private is tagged null record;

   function "=" (L, R : Tagged_Private) return Boolean is (False);
   --  Private description of `"="` of `Tagged_Private`

   type Derived_Tagged_Private is new Tagged_Private with null record;

   function "="
     (Left  : Explicit_Record;
      Right : Explicit_Record) return Boolean is (False);
   --  Private declaration of the explicit equal check operator

   type Derived_Tagged_Private_Public is new Tagged_Private with null record;

   type Derived_Tagged_Private_Private is new Tagged_Private with null record;

   function "="
     (Left  : Derived_Tagged_Private_Private;
      Right : Derived_Tagged_Private_Private) return Boolean is (False);
   --  Private description of `"="` of `Derived_Tagged_Private_Private`

   procedure Dummy;

   function "="
     (Left  : Derived_Tagged_Default_Public;
      Right : Derived_Tagged_Default_Public) return Boolean is (False);
   --  Private description of `"="` of `Derived_Tagged_Default_Public`

   function "="
     (Left  : Tagged_Public;
      Right : Tagged_Public) return Boolean is (False);
   --  Private description of `"="` of `Tagged_Public`

   function "="
     (Left  : Derived_Tagged_Public_Public;
      Right : Derived_Tagged_Public_Public) return Boolean is (False);
   --  Private description of `"="` of `Derived_Tagged_Public_Public`

   function "="
     (Left  : Derived_Tagged_Private_Public;
      Right : Derived_Tagged_Private_Public) return Boolean is (False);
   --  Private description of `"="` of `Derived_Tagged_Private_Public`

end Synthetics;
