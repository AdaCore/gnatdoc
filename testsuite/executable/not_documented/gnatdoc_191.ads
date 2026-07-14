--  Doc for GNATdoc_191

package GNATdoc_191 is

   generic
      with procedure Foo (Value : out Integer);
      --  Doc for foo
      --  @param Value bla

   package Bar
   is
      --  doc for bar
      procedure Baz (Value : out Integer);
      --  Doc for baz
      --  @param Value blabla
   end Bar;

   generic
      with procedure UFoo (UValue : out Integer);

   package UnBar
   is
      procedure UBaz (UValue : out Integer);
   end UnBar;

end GNATdoc_191;
