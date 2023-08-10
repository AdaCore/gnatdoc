--  This test check that expression functions that completes subprogram
--  declarations in the public part.
--
--  Refs eng/ide/gnatdoc#39.

package P is

   type T is tagged private;

   function "<" (Left, Right : T) return Boolean;

   function F (Self : T) return Integer;

   function FG return Integer;

private

   type T is tagged null record;

   function "<" (Left, Right : T) return Boolean is (False);

   function F (Self : T) return Integer is (0);

   function FG return Integer is (0);

end P;
