--  This is description of the package at the top of the compilation unit.
--
--  This package provides test cases of documented subprograms using GNAT
--  style.
with Interfaces;

package Subprograms_GNAT is

   pragma Preelaborate;

   --  This is description of the package at the top of the specification.

   type Abstract_Type is abstract tagged limited null record;
   --  Abstract tagged type to test abstract subprograms.

   ----------------
   -- Procedures --
   ----------------

   --  Tests of procedures declarations. It extensively test processing of the
   --  parameters specifications in different combinations. It allows to
   --  minimize number of tests for parameters of the functions, because the
   --  same code is used to process parameters of both procedures and
   --  functions. Some tests cover use of aspects: documentation between the
   --  procedure specification and aspects. Null and abstract procedures are
   --  not present in this section, see section for advanced features at the
   --  end of this specification.

   procedure Test_Procedure_Inline
     (X : Interfaces.Integer_64;  --  Value of X
      Y : Interfaces.IEEE_Float_64;
      --  Value of Y
      Z : Integer);               --  Value of Z
   --  This is description of the procedure with "inline" parameter's
   --  description.
   --
   --  @exception Constraint_Error Raised on some error condition.

   procedure Test_Procedure_Inline_Aspects
     (X : Interfaces.Integer_64;  --  Value of X
      Y : Interfaces.IEEE_Float_64;
      --  Value of Y
      Z : Integer)                --  Value of Z
        with Convention => Ada;
   --  This is description of the procedure with "inline" parameter's
   --  description and aspects.
   --  @exception Constraint_Error Raised on some error condition.

   procedure Test_Procedure_Inline_Before_With_Aspects
     (X : Interfaces.Integer_64;  --  Value of X
      Y : Interfaces.IEEE_Float_64;
      --  Value of Y
      Z : Integer)                --  Value of Z
   --  This is description of the procedure with "inline" parameter's
   --  description and aspects.
   --  @exception Constraint_Error Raised on some error condition.
        with Convention => Ada;

   procedure Test_Procedure_Inline_Before_Aspects
     (X : Interfaces.Integer_64;  --  Value of X
      Y : Interfaces.IEEE_Float_64;
      --  Value of Y
      Z : Integer) with           --  Value of Z
   --  This is description of the procedure with "inline" parameter's
   --  description and aspects.
   --  @exception Constraint_Error Raised on some error condition.
        Convention => Ada;

   procedure Test_Procedure
     (A : String;
      B : Character);
   --  This is description of the procedure with description of the
   --  parameters in comment block.
   --  @param A Value of A
   --  @param B Value of B

   procedure Test_Procedure_Multiple_Parameters
     (A, B, C : String;  --  Values of strings
      D       : Character);
   --  This is description of the procedure with description of the
   --  parameters in comment block.
   --  @param A Value of A
   --  @param D Value of D

   procedure Test_Procedure_Grouped_Parameters
     (A : String;
      B : String;  --  Value of B
      C : String;
      --  Values of strings

      D : Character);
   --  This is description of the procedure with description of the
   --  parameters in comment block.
   --  @param A Value of A
   --  @param D Value of D

   procedure Test_Procedure_Multiline_Parameters
     (A : String;  --  Value of A
      --  as well as more information about A.
      B : String;  --  Value of B
      C : String;
      --  Values of C
      --  as well as more information about C.
      D : Character);
   --  This is description of the procedure with description of the
   --  parameters in comment block.
   --  @param A And even more about A.
   --  @param D Value of D

   procedure Test_Single_Line;  --  This is single line comment for subprogram

   procedure Test (X : Integer);  --  Parameter X
   --  Procedure with parameter.

   ---------------
   -- Functions --
   ---------------

   --  These tests is mostly oriented to cover functions specific features,
   --  like return values. Some tests cover use of aspects. Expression and
   --  abstract functions are not present in this section, see section for
   --  advanced features at the end of this specification.

   function Test (X : Integer; Y : Integer) return Integer;
   --  Function with two parameters
   --
   --  @param X Value of X
   --  @param Y Value of Y
   --  @return Return value

   function Test_2 (X : Integer; Y : Integer)
     return       --  Multiline inlined description
       Integer;   --  of the return value
   --  Function with two parameters
   --
   --  @param X Value of X
   --  @param Y Value of Y

   function Test_Aspects_1 return Integer with Inline;
   --  Parameterless single line function declaration.

   function Test_Aspects_2 return Integer
   --  Parameterless single line function declaration.
     with Inline;

   function Test_Aspects_3 return Integer with
   --  Parameterless single line function declaration.
     Convention => Ada;

   function Test_Aspects_4
     return Integer with  --  Retun value is always positive
   --  Parameterless single line function declaration.
     Convention => Ada;

   --------------------
   -- Advanced cases --
   --------------------

   procedure Test_Null is null;
   --  Parameterless null subprogram.

   procedure Test_Abstract (Self : Abstract_Type) is abstract;
   --  Abstract procedure.

   function Test_Abstract (Self : Abstract_Type) return Boolean is abstract;
   --  Abstract function.

   function Test_Expression_1 return Integer is (0);
   --  Expression function.

   function Test_Expression_2
     return Integer
   --  Multiline expression function, documentation before expression.
       is (0);

   function Test_Expression_3
     return Integer
   --  Multiline expression function, documentation before expression, aspects
   --  present.
       is (0)
       with Inline;

   function Test_Expression_4
     return Integer
       is (0)
   --  Multiline expression function, documentation after expression, aspects
   --  present.
     with Inline;

   procedure Test_Procedure_With_Pragma;
   pragma Inline (Test_Procedure_With_Pragma);
   --  Documentation of the procedure with applied pragma.

   type Access_Procedure_1 is access procedure;
   --  Access to parameterless procedure.

   type Access_Procedure_2 is access procedure (X : Integer);  --  Value of X
   --  Access to procedure.

   type Access_Procedure_3 is access procedure (X, Y : Integer);
   --  Access to procedure with two parameters.
   --
   --  @param X Value of X
   --  @param Y Value of Y

   type Access_Function_1 is
     access function return Integer;  --  Return value
   --  Access to parameterless function.

   type Access_Function_2 is
     access function (X : Float) return Integer;
   --  Access to function
   --
   --  @param X Value of X
   --  @return Return value

private

   --  This is description of the package at the beginning of the private
   --  part of the specification.

end Subprograms_GNAT;
