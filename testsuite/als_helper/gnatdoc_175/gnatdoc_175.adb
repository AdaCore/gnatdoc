--  This package doesn't have specification intentionally.
--  It assumes that LAL is unable to resolve `Integer` type.

package body GNATdoc_175 is

   procedure Foo (X : in out Integer);

   procedure Bar (X : Integer);

   procedure Hello;

   procedure Foo (X : in out Integer) is
   begin
      X := X + 1;
   end Foo;

   procedure Bar (X : Integer) is
   begin
      null;
   end Bar;

   procedure Hello is
      XXX : Integer := 1;
   begin
      XXX := XXX + 2;
      Foo (XXX);
      Bar (XXX);
   end Hello;

end GNATdoc_175;
