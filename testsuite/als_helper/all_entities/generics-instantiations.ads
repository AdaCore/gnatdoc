--  Copyright header

--  Description of the package specification

with Interfaces;

package Generics.Instantiations is

   type Derived_Type is new Ada.Finalization.Controlled with null record;

   package Package_Instantiation is
     new Generic_Package
           (Private_Type              =>
              Ada.Strings.Unbounded.Unbounded_String,
            Derived_Type              => Derived_Type,
            Discrete_Type             => Boolean,
            Signed_Integer_Type       => Integer,
            Modular_Type              => Interfaces.Unsigned_32,
            Floating_Point_Type       => Float,
            Ordinary_Fixed_Point_Type => Ordinary_Fixed_Point_Type,
            Decimal_Fixed_Point_Type  => Decimal_Fixed_Point_Type,
            Array_Type                => Array_Type,
            Access_Type               => Access_Type,
            Interface_Type            => Interface_Type);

   function Function_Instantiation is new Generic_Function;

   procedure Procedure_Instantiation is new Generic_Procedure;

private

   procedure Dummy;

end Generics.Instantiations;
