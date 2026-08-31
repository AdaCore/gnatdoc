
package body Protecteds is

   protected body Protected_Object is

      --  Description of the protected object (body).

      entry Protected_Entry when True is
      -- Description of the protected entry (body).

         Dummy : Integer;
      begin
         Dummy := Protected_Function;
         Protected_Procedure;
         Protected_Entry;

         requeue Protected_Requeue_Entry;
      end Protected_Entry;

      entry Protected_Requeue_Entry when True is
      --  Description of the protected requeue entry (body).

      begin
         null;
      end Protected_Requeue_Entry;

      entry Protected_Entry_Family
        (for Index in Positive range 1 .. 10) when True is
      --  Description of the protected entry family (body).

         Dummy : Integer;
      begin
         Dummy := Index;
      end Protected_Entry_Family;

      function Protected_Function return Integer is
      --  Description of the protected function (body).

      begin
         return 0;
      end Protected_Function;

      procedure Protected_Procedure is
      --  Description of the protected procedure (body).

      begin
         null;
      end Protected_Procedure;

   end Protected_Object;

   protected body Protected_Type is

      --  Description of the protected type (body).

      entry Protected_Entry when True is
      -- Description of the protected entry (body).

         Dummy : Integer;
      begin
         Dummy := Protected_Function;
         Protected_Procedure;
         Protected_Entry;

         requeue Protected_Requeue_Entry;
      end Protected_Entry;

      entry Protected_Requeue_Entry when True is
      --  Description of the protected requeue entry (body).

      begin
         requeue Protected_Object.Protected_Requeue_Entry;
      end Protected_Requeue_Entry;

      entry Protected_Entry_Family
        (for Index in Positive range 1 .. 10) when True is
      --  Description of the protected entry family (body).

         Dummy : Integer;
      begin
         Dummy := Index;
      end Protected_Entry_Family;

      function Protected_Function return Integer is
      --  Description of the protected function (body).

      begin
         return 0;
      end Protected_Function;

      procedure Protected_Procedure is
      --  Description of the protected procedure (body).

      begin
         null;
      end Protected_Procedure;

   end Protected_Type;

   PO : Protected_Type;

   Dummy : Integer;

begin
   Dummy := Protected_Object.Protected_Function;
   Protected_Object.Protected_Procedure;
   Protected_Object.Protected_Entry;
   Protected_Object.Protected_Entry_Family (1);

   Dummy := PO.Protected_Function;
   PO.Protected_Procedure;
   PO.Protected_Entry;
   PO.Protected_Entry_Family (1);
end Protecteds;
