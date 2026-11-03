package Types is

   type Root_Type is tagged null record;
   --  Visible root type.

   type Enumeration_Type is (One, Two);
   --  @exclude

   type Signed_Integer_Type is range -10 .. 10;
   --  @exclude

   type Modular_Integer_Type is mod 256;
   --  @exclude

   type Floating_Point_Type is digits 6;
   --  @exclude

   type Ordinary_Fixed_Point_Type is delta 0.125 range -10.0 .. 10.0;
   --  @exclude

   type Decimal_Fixed_Point_Type is delta 0.01 digits 6;
   --  @exclude

   type Derived_Type is new Integer;
   --  @exclude

   type Array_Type is array (Positive range <>) of Integer;
   --  @exclude

   type Constrained_Array_Type is array (1 .. 10) of Integer;
   --  @exclude

   type Record_Type (Discriminant : Boolean) is record
      Component : Integer;
   end record;
   --  @exclude

   type Null_Record_Type is null record;
   --  @exclude

   type Tagged_Record_Type is tagged record
      Component : Integer;
   end record;
   --  @exclude

   type Tagged_Null_Record_Type is tagged null record;
   --  @exclude

   type Record_Extension_Type is new Root_Type with record
      Component : Integer;
   end record;
   --  @exclude

   type Null_Extension_Type is new Root_Type with null record;
   --  @exclude

   type Interface_Type is interface;
   --  @exclude

   type Access_Type is access all Integer;
   --  @exclude

   type Access_Constant_Type is access constant Integer;
   --  @exclude

   type Access_Procedure_Type is access procedure (Value : Integer);
   --  @exclude

   type Access_Function_Type is access function return Integer;
   --  @exclude

   type Private_Type is private;
   --  @exclude

   type Tagged_Private_Type is tagged private;
   --  @exclude

   type Private_Extension_Type is new Root_Type with private;
   --  @exclude

   subtype Subtype_Declaration is Integer range 1 .. 10;
   --  @exclude

   task type Task_Type;
   --  @exclude

   protected type Protected_Type is
      --  @exclude

      procedure Operation;

   end Protected_Type;

private

   type Private_Type is null record;

   type Tagged_Private_Type is tagged null record;

   type Private_Extension_Type is new Root_Type with null record;

end Types;
