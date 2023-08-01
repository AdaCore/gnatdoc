
generic
   type Item_T is private;
   -- Item.
package Test_VB10_011 is

   type Foo_1_T
     (Baz_1 : Natural
      -- A baz.
     ) is private;
   -- Foo type.

   type Foo_2_T
     (Baz_2 : Natural
      -- A baz.
     ) is private;
   -- Foo type.

   type Foo_3_T
     (Baz_3 : Natural
     ) is private;
   -- Foo type.
   -- @field Baz_3 A baz.

   type Foo_4_T
     (Baz_4 : Natural
      -- A baz.
     ) is private;
   -- Foo type.

   type Foo_5_T
     (Baz_5 : Natural
     ) is private;
   -- Foo type.
   -- @field Baz_5 A baz.

private

   type Foo_1_T
     (Baz_1 : Natural
     ) is null record;

   type Foo_2_T
     (Baz_2 : Natural
      -- A baz.
     ) is null record;

   type Foo_3_T
     (Baz_3 : Natural
     ) is null record;
   -- @field Baz_3 A baz.

   type Foo_4_T
     (Baz_4 : Natural
     ) is null record;
   -- @field Baz_4 A baz.

   type Foo_5_T
     (Baz_5 : Natural
      -- A baz.
     ) is null record;

end Test_VB10_011;
