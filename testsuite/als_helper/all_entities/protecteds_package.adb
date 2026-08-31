
with Protecteds;

package body Protecteds_Package is

   PO : Protecteds.Protected_Type;

   protected Requeue_Object is
      entry Requeue_To_Object;
      entry Requeue_To_Type;
   end Requeue_Object;

   protected body Requeue_Object is

      entry Requeue_To_Object when True is
      begin
         requeue Protecteds.Protected_Object.Protected_Requeue_Entry;
      end Requeue_To_Object;

      entry Requeue_To_Type when True is
      begin
         requeue PO.Protected_Requeue_Entry;
      end Requeue_To_Type;

   end Requeue_Object;

   procedure Dummy is
      Dummy : Integer;
   begin
      Dummy := Protecteds.Protected_Object.Protected_Function;
      Protecteds.Protected_Object.Protected_Procedure;
      Protecteds.Protected_Object.Protected_Entry;
      Protecteds.Protected_Object.Protected_Entry_Family (1);

      Dummy := PO.Protected_Function;
      PO.Protected_Procedure;
      PO.Protected_Entry;
      PO.Protected_Entry_Family (1);
   end Dummy;

end Protecteds_Package;
