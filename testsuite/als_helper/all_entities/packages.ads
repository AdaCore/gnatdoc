--  Copyright header

--  Description of the package specification

package Packages is

   package Public_Nested is

      --  Description of the nested package specification in public part

      procedure Dummy;

   end Public_Nested;

   procedure Dummy;

private

   package Private_Nested is

      --  Description of the nested package specification in private part

      procedure Dummy;

   end Private_Nested;

end Packages;
