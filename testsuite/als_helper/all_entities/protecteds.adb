
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
      end Protected_Entry;

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
      end Protected_Entry;

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

   Dummy := PO.Protected_Function;
   PO.Protected_Procedure;
   PO.Protected_Entry;
end Protecteds;
