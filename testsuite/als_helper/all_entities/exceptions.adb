with Ada.Exceptions;

package body Exceptions is

   procedure Dummy is
   begin
      begin
         raise Test_Exception;

      exception
         when Test_Exception =>
            null;
      end;

      declare
         use type Ada.Exceptions.Exception_Id;

      begin
         raise Test_Exception;

      exception
         when E : Test_Exception =>  --  Documentation
            if Ada.Exceptions.Exception_Identity (E)
                 = Test_Exception'Identity
            then
               raise;
            end if;
      end;
   end Dummy;

end Exceptions;
