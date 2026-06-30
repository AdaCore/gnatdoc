
with Protecteds;

package body Protecteds_Package is

   PO : Protecteds.Protected_Type;

   procedure Dummy is
      Dummy : Integer;
   begin
      Dummy := Protecteds.Protected_Object.Protected_Function;
      Protecteds.Protected_Object.Protected_Procedure;
      Protecteds.Protected_Object.Protected_Entry;

      Dummy := PO.Protected_Function;
      PO.Protected_Procedure;
      PO.Protected_Entry;
   end Dummy;

end Protecteds_Package;