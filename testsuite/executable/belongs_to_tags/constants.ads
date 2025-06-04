
package Constants is

   type T is tagged limited null record;

   C : constant T := (others => <>);

   B : constant T := (others => <>);
   --  @belongs-to T

end Constants;
