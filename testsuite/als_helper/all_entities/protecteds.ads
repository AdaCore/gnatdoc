
package Protecteds is

   protected Protected_Object is

      --  Description of the protected object (specification).

      procedure Protected_Procedure;
      --  Description of the protected procedure (specification).

      function Protected_Function return Integer;
      --  Description of the protected function (specification).

      entry Protected_Entry;
      -- Description of the protected entry (specification).

   end Protected_Object;

   protected type Protected_Type is

      --  Description of the protected type (specification).

      procedure Protected_Procedure;
      --  Description of the protected procedure (specification).

      function Protected_Function return Integer;
      --  Description of the protected function (specification).

      entry Protected_Entry;
      -- Description of the protected entry (specification).

   end Protected_Type;

end Protecteds;