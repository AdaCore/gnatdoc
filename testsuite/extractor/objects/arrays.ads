pragma Ada_2022;

package PA is

   A : array (1 .. 5) of Integer := [1, 2, 3, 4, 5];
   --  Anonymous: Code snippet contains complete initialization expression.

   B : array (1 .. 5) of Integer :=
     [1,
      2,
      3,
      4,
      5];
   --  Anonymous Code snippet contains few items of initialization expression.

   type Integer_Array is array (Positive range <>) of Integer;

   IA : Integer_Array (1 .. 5) := [1, 2, 3, 4, 5];
   --  Variable: Code snippet contains complete initialization expression.
   IB : constant Integer_Array (1 .. 5) := [1, 2, 3, 4, 5];
   --  Constant: Code snippet contains complete initialization expression.

   IC : Integer_Array (1 .. 5) :=
     [1,
      2,
      3,
      4,
      5];
   --  Variable: Code snippet contains few items of initialization expression.
   ID : constant Integer_Array (1 .. 5) :=
     [1,
      2,
      3,
      4,
      5];
   --  Constant: Code snippet contains few items of initialization expression.

   S : constant String := "`String` type is an array too";
   --  `String` type is an array, and initialization expression can be a string
   --  literal.

end PA;
