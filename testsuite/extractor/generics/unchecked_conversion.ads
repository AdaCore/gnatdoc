--  Copyright header

--  An unchecked type conversion can be achieved by a call to an instance of
--  the generic function Unchecked_Conversion.

generic
   type Source (<>) is limited private;
   type Target (<>) is limited private;

function Unchecked_Conversion (S : Source) return Target;

pragma No_Elaboration_Code_All (Unchecked_Conversion);
pragma Pure (Unchecked_Conversion);
pragma Import (Intrinsic, Unchecked_Conversion);
