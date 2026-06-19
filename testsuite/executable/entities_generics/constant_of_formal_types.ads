generic
   type T;
   type T_Access is access all T;

   type Element_Type is private;
   type Index_Type is range <>;

   type Array_Type is array (Index_Type range <>) of Element_Type;

package Constant_Of_Formal_Types is

   Null_T : constant T_Access := null;

   Empty_Array : constant Array_Type
     (Index_Type'Succ (Index_Type'First) .. Index_Type'First)
       := (others => <>);

end Constant_Of_Formal_Types;
