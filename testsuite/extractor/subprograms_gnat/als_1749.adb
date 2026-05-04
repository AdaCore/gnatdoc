
package body ALS_1749 is

   procedure ALS_1749_0
     (X : Integer;
      Y : Integer)
   is
      Z : Integer := X;
      --  This is description of the `Z` object

   begin
      for J in X .. Y loop
         --  This is description of the loop

         Z := Z + J;
      end loop;
   end ALS_1749_0;

   procedure ALS_1749_1
     (X : Integer;  --  Description of the `X` parameter
      Y : Integer)  --  Description of the `Y` parameter
   is
      Z : Integer := X;
      --  This is description of the `Z` object

   begin
      for J in X .. Y loop
         --  This is description of the loop

         Z := Z + J;
      end loop;
   end ALS_1749_1;

   procedure ALS_1749_2
     (X : Integer;  --  Description of the `X` parameter
      Y : Integer) is  --  Description of the `Y` parameter

      Z : Integer := X;
      --  This is description of the `Z` object

   begin
      for J in X .. Y loop
         --  This is description of the dummy magic of the loop

         Z := Z + J;
      end loop;
   end ALS_1749_2;

   procedure ALS_1749_3
     (X : Integer;     --  Description of the `X` parameter
      Y : Integer) is  --  Description of the `Y` parameter
   begin
      for J in X .. Y loop
         --  This is description of the loop

         null;
      end loop;
   end ALS_1749_3;

   procedure ALS_1749_4
     (X : Integer;  --  Description of the `X` parameter
      Y : Integer)  --  Description of the `Y` parameter
   is
   begin
      for J in X .. Y loop
         --  This is description of the loop

         null;
      end loop;
   end ALS_1749_4;

   procedure ALS_1749_11
     (X : Integer;     --  Description of the `X` parameter
      Y :              --  Description of the `Y` parameter
          Integer) is  --  continuation of 'Y'
      --  Description of both parameters
   begin
      for J in X .. Y loop
         --  This is description of the loop

         null;
      end loop;
   end ALS_1749_11;

   procedure ALS_1749_12
     (X : Integer;  --  Description of the `X` parameter
      Y :           --  Description of the `Y` parameter
          Integer)  --  continuation of 'Y'
      --  Description of both parameters
   is
   begin
      for J in X .. Y loop
         --  This is description of the loop

         null;
      end loop;
   end ALS_1749_12;

   procedure ALS_1749_13
     (X : Integer;  --  Description of the `X` parameter
      Y :           --  Description of the `Y` parameter
          Integer)  --  continuation of 'Y'
   is
   begin
      for J in X .. Y loop
         --  This is description of the loop

         null;
      end loop;
   end ALS_1749_13;

   procedure ALS_1749_14
     (X : Integer;     --  Description of the `X` parameter
      Y :              --  Description of the `Y` parameter
          Integer) is  --  continuation of 'Y'
      --  Description of the both parameters

      Z : Integer := X;
      --  This is description of the `Z` object

   begin
      for J in X .. Y loop
         --  This is description of the loop

         Z := Z + J;
      end loop;
   end ALS_1749_14;

   procedure ALS_1749_15
     (X : Integer;  --  Description of the `X` parameter
      Y :           --  Description of the `Y` parameter
          Integer)  --  continuation of 'Y'
      --  Description of the both parameters

   is
      Z : Integer := X;
      --  This is description of the `Z` object

   begin
      for J in X .. Y loop
         --  This is description of the loop

         Z := Z + J;
      end loop;
   end ALS_1749_15;

end ALS_1749;
