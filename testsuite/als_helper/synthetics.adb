
package body Synthetics is

   procedure Dummy is
   begin
      declare
         A : Implicit_Record;
         B : Implicit_Record;

      begin
         if A = B then
            null;
         end if;

         if A /= B then
            null;
         end if;
      end;

      declare
         A : Derived_Implicit_Record;
         B : Derived_Implicit_Record;

      begin
         if A = B then
            null;
         end if;

         if A /= B then
            null;
         end if;
      end;

      declare
         A : Explicit_Record;
         B : Explicit_Record;

      begin
         if A = B then
            null;
         end if;

         if A /= B then
            null;
         end if;
      end;

      declare
         A : Derived_Explicit_Record;
         B : Derived_Explicit_Record;

      begin
         if A = B then
            null;
         end if;

         if A /= B then
            null;
         end if;
      end;

      declare
         A : Integer_32 := -1;

      begin
         if A > 3 or A >= 3 or A < 3 or A <= 3 then
            null;
         end if;

         A := abs A;
         A := A / 2;
         A := A - 2;
         A := -A;
         A := A mod 3;
         A := A * 5;
         A := A + 3;
         A := +A;
         A := A ** 7;
         A := A rem 4;
      end;

      declare
         A : Derived_Integer_32 := -1;

      begin
         if A > 3 or A >= 3 or A < 3 or A <= 3 then
            null;
         end if;

         A := abs A;
         A := A / 2;
         A := A - 2;
         A := -A;
         A := A mod 3;
         A := A * 5;
         A := A + 3;
         A := +A;
         A := A ** 7;
         A := A rem 4;
      end;

      declare
         A : Unsigned_32 := 5;

      begin
         A := A and 10;
         A := not A;
         A := A or 15;
         A := A xor 31;
      end;

      declare
         A : Derived_Unsigned_32 := 5;

      begin
         A := A and 10;
         A := not A;
         A := A or 15;
         A := A xor 31;
      end;

      declare
         A : Integer_32_Array := (1, 2);
         B : Integer_32_Array := (3, 4, 5);
         C : Integer_32_Array := A & B;

      begin
         null;
      end;

      declare
         A : Derived_Integer_32_Array := (1, 2);
         B : Derived_Integer_32_Array := (3, 4, 5);
         C : Derived_Integer_32_Array := A & B;

      begin
         null;
      end;

      declare
         A : Tagged_Default;
         B : Tagged_Default;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Default;
         B : Derived_Tagged_Default;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Default_Private;
         B : Derived_Tagged_Default_Private;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Default_Public;
         B : Derived_Tagged_Default_Public;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Tagged_Public;
         B : Tagged_Public;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Public;
         B : Derived_Tagged_Public;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Public_Public;
         B : Derived_Tagged_Public_Public;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Public_Private;
         B : Derived_Tagged_Public_Private;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Tagged_Private;
         B : Tagged_Private;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Private;
         B : Derived_Tagged_Private;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Private_Private;
         B : Derived_Tagged_Private_Private;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;

      declare
         A : Derived_Tagged_Private_Public;
         B : Derived_Tagged_Private_Public;

      begin
         if A = B or B /= A then
            null;
         end if;
      end;
   end Dummy;

end Synthetics;
