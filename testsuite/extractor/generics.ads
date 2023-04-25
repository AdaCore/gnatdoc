
--  Test cases for generics declarations

package Generics is

   --  This generic package has set of formal parameters of all types.

   generic
      type Private_Type is abstract tagged limited private;
      --  Description of the formal private type.

      type Derived_Type is abstract limited new Private_Type with private;
      --  Description of the formal derived type.

      type Discrete_Type is (<>);
      --  Description of the formal discrete type.

      type Signed_Integer_Type is range <>;
      --  Description of the formal signed integer type.

      type Modular_Type is mod <>;
      --  Description of the formal modular type.

      type Floating_Point_Type is digits <>;
      --  Description of the formal floating point type.

      type Ordinary_Fixed_Point_Type is delta <>;
      --  Description of the ordinary fixed point type.

      type Decimal_Fixed_Point_Type is delta <> digits <>;
      --  Description of the decimal fixed point type.

      type Array_Type is array (Signed_Integer_Type range <>) of Modular_Type;
      --  Description of the array type.

      type Object_Access_Type is access all Derived_Type'Class;
      --  Description of the object access type.

      type Procedure_Access_Type is access procedure;
      --  Description of the access to parameterless procedure type.

      type Function_Access_Type is access function return Floating_Point_Type;
      --  Description of the access to parameterless function type.

      type Interface_Type is synchronized interface;
      --  Description of the interface type.

   package All_Types is

   end All_Types;

   --  This generic package has set of formal parameters of access to
   --  subprogram and subprogram.
   --
   --  @formal Procedure_Access_Type Access to procedure
   --  @formal Function_Access_Type Access to function
   --  @formal Procedure_P Formal procedure
   --  @formal Function_F Formal function

   generic

      type Procedure_Access_Type is access procedure
        (X : Integer;   --  Value of X
         Y : Integer);  --  Value of Y

      type Function_Access_Type is access function
        (X : Integer;     -- Value of X
         Y : Integer)     -- Value of Y
         return Integer;  --  Return value

      with procedure Procedure_P
        (X : Integer;   --  Value of X
         Y : Integer);  --  Value of Y

      with function Function_F
        (X : Integer;     -- Value of X
         Y : Integer)     -- Value of Y
         return Integer;  --  Return value

   package All_Subprograms is

   end All_Subprograms;

   --  Formal objects

   generic
      X, Y : Integer;
      --  Description of the X and Y formal objects.

      Z : Integer;
      --  Description of the Z formal object.

   package Objects is

   end Objects;

   generic
      with package Types is new All_Types (<>);

   package My_Types is

   end My_Types;

   --  Generic procedure

   generic
      type T is private;
      --  Description of the formal parameter.

   procedure Generic_Procedure (X : T);
   --  Description of the generic procedure

   --  Generic function

   generic
      type T is private;

   function Generic_Function (X : T) return T;
   --  Description of the generic function
   --
   --  @param X Description of the parameter
   --  @returns Description of the return value
   --
   --  @formal T Description of the formal type

   generic
      type Private_Unknown_Discriminants_Type (<>) is private;

      type Private_Known_Discriminants_Type (X : Integer) is private;

   package Discriminanted_Types is

   end Discriminanted_Types;

end Generics;
