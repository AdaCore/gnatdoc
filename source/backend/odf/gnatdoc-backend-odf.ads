------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
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

package GNATdoc.Backend.ODF is

   type ODF_Backend is new Abstract_Backend with private;

private

   type ODF_Backend is new Abstract_Backend with record
      null;
   end record;

   overriding procedure Initialize (Self : in out ODF_Backend);

   overriding procedure Generate (Self : in out ODF_Backend);

   overriding procedure Add_Command_Line_Options
     (Self   : ODF_Backend;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class);

   overriding procedure Process_Command_Line_Options
     (Self   : in out ODF_Backend;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class);

   overriding function Name
     (Self : in out ODF_Backend) return VSS.Strings.Virtual_String is ("odf");

end GNATdoc.Backend.ODF;
