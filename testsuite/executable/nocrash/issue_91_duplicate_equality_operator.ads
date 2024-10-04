with Ada.Finalization;

package Issue_91_Duplicate_Equality_Operator is

   type Vector is tagged private;
   
   overriding function "=" (Left : Vector; Right : Vector) return Boolean;
   
private
   
   type Vector is new Ada.Finalization.Controlled with null record;

end Issue_91_Duplicate_Equality_Operator;
