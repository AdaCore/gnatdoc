--  Copyright header

--  Description of the package specification

with Generic_Function_Instantiation;
with Generic_Package_Instantiation;
with Generic_Procedure_Instantiation;

package body Generics_Package is

   procedure Dummy is
   begin
      Generic_Package_Instantiation.Dummy;

      declare
         X : Integer := Generic_Function_Instantiation;

      begin
         null;
      end;

      Generic_Procedure_Instantiation;
   end Dummy;

end Generics_Package;
