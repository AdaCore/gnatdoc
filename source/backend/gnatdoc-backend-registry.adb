------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2024, AdaCore                        --
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

with GNATdoc.Backend.HTML;
with GNATdoc.Backend.RST.PT;

package body GNATdoc.Backend.Registry is

   --------------------
   -- Create_Backend --
   --------------------

   function Create_Backend
     (Name : VSS.Strings.Virtual_String) return Backend_Access
   is
      use type VSS.Strings.Virtual_String;

   begin
      if Name = "html" then
         return new GNATdoc.Backend.HTML.HTML_Backend;

      elsif Name = "rst" then
         return new GNATdoc.Backend.RST.RST_Backend;

      elsif Name = "rstpt" then
         return new GNATdoc.Backend.RST.PT.PT_RST_Backend;
      end if;

      return null;
   end Create_Backend;

end GNATdoc.Backend.Registry;
