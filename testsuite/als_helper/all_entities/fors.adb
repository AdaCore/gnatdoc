
package body Fors is

   procedure Dummy is
   begin
      for J in 1 .. 10 loop  --  Description of the `for` loop object
         exit when J > 20;
      end loop;
   end Dummy;

end Fors;
