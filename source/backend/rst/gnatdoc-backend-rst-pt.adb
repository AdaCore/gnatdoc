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

package body GNATdoc.Backend.RST.PT is

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (Self : in out PT_RST_Backend) is
   begin
      RST_Backend_Base (Self).Initialize;

      Self.OOP_Mode           := True;
      Self.Alphabetical_Order := False;
   end Initialize;

   ----------
   -- Name --
   ----------

   overriding function Name
     (Self : in out PT_RST_Backend) return VSS.Strings.Virtual_String is
   begin
      return "rstpt";
   end Name;

end GNATdoc.Backend.RST.PT;
