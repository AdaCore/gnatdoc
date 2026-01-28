
package body Returns is

   procedure Dummy is

      function My_Function return Integer is
      begin
         return Result : Integer do  --  Documentation of the Result
            Result := 5;
         end return;
      end My_Function;

   begin
      null;
   end Dummy;

end Returns;
