--
--  Copyright (C) 2025, AdaCore
--
--  SPDX-License-Identifier: GPL-3.0
--

--  This file is stub to build GNATdoc outside of the Alire environment. Alire
--  will overwrite it during builds.

pragma Restrictions (No_Elaboration_Code);
pragma Style_Checks (Off);

package Gnatdoc_Config is
   pragma Pure;

   Crate_Version : constant String := "%VERSION% (%DATE%)";

end Gnatdoc_Config;
