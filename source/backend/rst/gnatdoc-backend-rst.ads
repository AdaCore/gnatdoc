------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2023, AdaCore                        --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

package GNATdoc.Backend.RST is

   type RST_Backend is new Abstract_Backend with private;

private

   type RST_Backend_Base (Pass_Through : Boolean) is
     abstract new Abstract_Backend with record
      OOP_Mode : Boolean := False;
   end record;

   overriding procedure Initialize (Self : in out RST_Backend_Base);

   overriding procedure Generate (Self : in out RST_Backend_Base);

   type RST_Backend is
     new RST_Backend_Base (False) with null record;

   overriding function Name
     (Self : in out RST_Backend) return VSS.Strings.Virtual_String;

end GNATdoc.Backend.RST;
