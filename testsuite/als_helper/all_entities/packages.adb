--  Copyright header

--  Description of the package body

package body Packages is

   package Body_Nested is

      --  Description of the nested package specification in body

      procedure Dummy;

   end Body_Nested;

   -----------
   -- Dummy --
   -----------

   procedure Dummy is
   begin
      null;
   end Dummy;

   -----------------
   -- Body_Nested --
   -----------------

   package body Body_Nested is

      --  Description of the nested package body in body

      procedure Dummy is
      begin
         null;
      end Dummy;

   end Body_Nested;

   -------------------
   -- Public_Nested --
   -------------------

   package body Public_Nested is

      --  Description of the nested package body in public part

      procedure Dummy is
      begin
         Private_Nested.Dummy;
      end Dummy;

   end Public_Nested;

   --------------------
   -- Private_Nested --
   --------------------

   package body Private_Nested is

      --  Description of the nested package body in private part

      procedure Dummy is
      begin
         Packages.Body_Nested.Dummy;
      end Dummy;

   end Private_Nested;

end Packages;
