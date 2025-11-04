------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2023-2025, AdaCore                     --
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
      OOP_Mode           : Boolean := False;
      Alphabetical_Order : Boolean := True;
   end record;

   overriding procedure Initialize (Self : in out RST_Backend_Base);

   overriding procedure Generate (Self : in out RST_Backend_Base);

   overriding procedure Add_Command_Line_Options
     (Self   : RST_Backend_Base;
      Parser : in out VSS.Command_Line.Parsers.Command_Line_Parser'Class);

   overriding procedure Process_Command_Line_Options
     (Self   : in out RST_Backend_Base;
      Parser : VSS.Command_Line.Parsers.Command_Line_Parser'Class);

   type RST_Backend is
     new RST_Backend_Base (False) with null record;

   overriding function Name
     (Self : in out RST_Backend) return VSS.Strings.Virtual_String;

   function Documentation_File_Name
     (Entity : GNATdoc.Entities.Entity_Information)
      return VSS.Strings.Virtual_String;
   --  Return name of the RST file to generate documentation for the given
   --  entity.

end GNATdoc.Backend.RST;
