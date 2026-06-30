
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

end Protecteds;