
package body Exceptions_Renamings is

   procedure Dummy is
   begin
      begin
         raise Renamed_Test_Exception;

      exception
         when Renamed_Test_Exception =>
            null;
      end;
   end Dummy;

end Exceptions_Renamings;
