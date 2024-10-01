
--  This is test data for test of documentation extraction for renamings.

with Pkg;

package Renamings is

   RE : exception renames Pkg.E;
   --  Documentation for exception renaming

   RK : Integer renames Pkg.K;
   --  Documentation for object renaming

   package RPkg renames Pkg;
   --  Documentation for package renaming

   procedure RP renames Pkg.P;
   --  Documentation for procedure renaming

   function RF return Integer renames Pkg.F;
   --  Documentation for function renaming

   generic
   package RGPkg renames Pkg.GPkg;
   --  Documentation for generic package renaming

   generic
   procedure RGP renames Pkg.GP;
   --  Documentation for generic procedure renaming

   generic
   function RGF renames Pkg.GF;
   --  Documentation for generic function renaming

end Renamings;
