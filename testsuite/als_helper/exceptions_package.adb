with Exceptions; use Exceptions;

package body Exceptions_Package is

   procedure Dummy is
   begin
      begin
         raise Test_Exception;

      exception
         when Test_Exception =>
            null;
      end;
   end Dummy;

end Exceptions_Package;
