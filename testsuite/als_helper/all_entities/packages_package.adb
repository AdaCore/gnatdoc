with Packages;
with Packages_Renaming;

package body Packages_Package is

   procedure Dummy is
   begin
      Packages.Dummy;
      Packages_Renaming.Dummy;
   end Dummy;

end Packages_Package;
