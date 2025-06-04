
package Subprograms is

   type T1 is tagged null record;

   type T2 is tagged null record;

   type I1 is interface;

   type I2 is interface;

   function PT1 (Self : T1'Class) return T2;

   function PT2 (Self : T1'Class) return T2;
   --  @belongs-to T2

   function DT1 (Self : T1) return T2'Class;

   function DT2 (Self : T1) return T2'Class;
   --  @belongs-to T2

   function PI1 (Self : I1'Class) return I2 is abstract;

   function PI2 (Self : I1'Class) return I2 is abstract;
   --  @belongs-to I2

   function PI1 (Self : I1) return I2'Class is abstract;

   function PI2 (Self : I1) return I2'Class is abstract;
   --  @belongs-to I2

end Subprograms;
