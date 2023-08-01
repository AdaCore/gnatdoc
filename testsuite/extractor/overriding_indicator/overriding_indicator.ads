
--  Test of extraction of the code snippet for subprograms with overriding
--  keyword.

package Overriding_Indicator is

   type T1 is abstract tagged limited null record;

   procedure P1 (Self : T1) is abstract;

   procedure P2
     (Self : T1;
      X    : Integer) is abstract;

   procedure P3 (Self : T1;
                 X    : Integer) is abstract;

   procedure P4 (Self : T1;
      X    : Integer) is abstract;

   function F1 (Self : T1) return Integer is abstract;

   type T2 is abstract new T1 with null record;

   overriding procedure P1 (Self : T2);

   overriding procedure P2
     (Self : T2;
      X    : Integer);

   overriding procedure P3 (Self : T2;
                            X    : Integer);

   overriding procedure P4 (Self : T2;
      X    : Integer);

   type T3 is abstract new T1 with null record;

   overriding
   procedure P1 (Self : T3);

   overriding
   procedure P2
     (Self : T3;
      X    : Integer);

   overriding
   procedure P3 (Self : T3;
                 X    : Integer);

   overriding
   procedure P4 (Self : T3;
      X    : Integer);

   type T4 is abstract new T1 with null record;

   overriding
   procedure P1 (Self : T4) is null;

   overriding
   procedure P2
     (Self : T4;
      X    : Integer) is null;

   overriding
   procedure P3 (Self : T4;
                 X    : Integer) is null;

   overriding
   procedure P4 (Self : T4;
      X    : Integer) is null;

   overriding
   function F1 (Self : T4) return Integer is (0);

   type T5 is abstract new T1 with null record;

   not overriding procedure P11 (Self : T5) is abstract;

   not overriding procedure P12
     (Self : T5;
      X    : Integer) is abstract;

   not overriding procedure P13 (Self : T5;
                                 X    : Integer) is abstract;

   not overriding procedure P14 (Self : T5;
      X    : Integer) is abstract;

   not overriding function F11 (Self : T5) return Integer is abstract;

   type T6 is abstract new T1 with null record;

   not overriding
   procedure P11 (Self : T6) is abstract;

   not overriding
   procedure P12
     (Self : T6;
      X    : Integer) is abstract;

   not overriding
   procedure P13 (Self : T6;
                  X    : Integer) is abstract;

   not overriding
   procedure P14 (Self : T6;
      X    : Integer) is abstract;

   not overriding
   function F11 (Self : T6) return Integer is abstract;

end Overriding_Indicator;
