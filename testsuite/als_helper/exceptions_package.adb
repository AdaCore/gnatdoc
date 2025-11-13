with Exceptions;
with Exceptions_Renamings;

package body Exceptions_Package is

   procedure Dummy is
   begin
      begin
         raise Exceptions.Test_Exception;

      exception
         when Exceptions.Test_Exception =>
            null;
      end;

      begin
         raise Exceptions_Renamings.Renamed_Test_Exception;

      exception
         when Exceptions_Renamings.Renamed_Test_Exception =>
            null;
      end;
   end Dummy;

end Exceptions_Package;
