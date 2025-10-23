
package body Exceptions is

   procedure Dummy is
   begin
      begin
         raise Test_Exception;

      exception
         when Test_Exception =>
            null;
      end;
   end Dummy;

end Exceptions;
