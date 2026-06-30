--  Copyright header

--  Description of the package body

with Interfaces;

package body Generics is

   procedure Dummy is
   begin
      null;
   end Dummy;

   function Generic_Function return Integer is
   begin
      return 0;
   end Generic_Function;

   package body Generic_Package is
      --  Description of the generic package body

      Private_Object              : Private_Type;
      Derived_Object              : Derived_Type;
      Discrete_Object             : Discrete_Type;
      Signed_Integer_Object       : Signed_Integer_Type;
      Modular_Object              : Modular_Type;
      Floating_Point_Object       : Floating_Point_Type;
      Ordinary_Fixed_Point_Object : Ordinary_Fixed_Point_Type;
      Decimal_Fixed_Point_Object  : Decimal_Fixed_Point_Type;
      Array_Object                : Array_Type (1 .. 1);
      Access_Object               : Access_Type;

      procedure Interface_Dummy (Self : Interface_Type) is null;

      function Interface_Object return access Interface_Type'Class is (null);

      procedure Dummy is
      begin
         Signed_Integer_Object := Formal_Concrete_Function;
         Formal_Concrete_Procedure;
         Signed_Integer_Object := Interface_Object.Formal_Abstract_Function;
         Interface_Object.Formal_Abstract_Procedure;
      end Dummy;

   end Generic_Package;

   procedure Generic_Procedure is
   begin
      null;
   end Generic_Procedure;

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
            Interface_Type            => Interface_Type,
            Formal_Concrete_Function  => Concrete_Function,
            Formal_Concrete_Procedure => Concrete_Procedure,
            Formal_Abstract_Function  => Concrete_Abstract_Function,
            Formal_Abstract_Procedure => Concrete_Abstract_Procedure);

   function Function_Instantiation is new Generic_Function;

   procedure Procedure_Instantiation is new Generic_Procedure;

end Generics;
