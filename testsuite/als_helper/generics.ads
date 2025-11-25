--  Copyright header

--  Description of the package specification

with Ada.Finalization;
with Ada.Strings.Unbounded;

package Generics is

   generic
      type Private_Type is private;
      --  Description of the formal private type

      type Derived_Type is new Ada.Finalization.Controlled with private;
      --  Description of the formal derived type

      type Discrete_Type is (<>);
      --  Description of the formal discrete type

      type Signed_Integer_Type is range <>;
      --  Description of the formal signed integer type

      type Modular_Type is mod <>;
      --  Description of the formal modular type

      type Floating_Point_Type is digits <>;
      --  Description of the formal floating point type

      type Ordinary_Fixed_Point_Type is delta <>;
      --  Description of the formal ordinary fixed point type

      type Decimal_Fixed_Point_Type is delta <> digits <>;
      --  Description of the formal decimal fixed point type

      type Array_Type is array (Positive range <>) of Discrete_Type;
      --  Description of the formal array type

      type Access_Type is access all Private_Type;
      --  Description of the formal access type

      type Interface_Type is interface;
      --  Description of the formal interface type

   package Generic_Package is
      --  Description of the generic package specification

      procedure Dummy;

   end Generic_Package;

   generic
   function Generic_Function return Integer;
   --  Description of the generic function specification

   generic
   procedure Generic_Procedure;
   --  Description of the generic procedure specification

   type Derived_Type is new Ada.Finalization.Controlled with null record;

   type Ordinary_Fixed_Point_Type is delta 0.001 range -1.0 .. 1.0;

   type Decimal_Fixed_Point_Type is delta 0.001 digits 5;

   type Array_Type is array (Positive range <>) of Boolean;

   type Access_Type is access all Ada.Strings.Unbounded.Unbounded_String;

   type Interface_Type is interface;

private

   procedure Dummy;

end Generics;
