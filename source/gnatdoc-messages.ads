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

with Ada.Exceptions;

with GNAT.Source_Info;

package GNATdoc.Messages is

   procedure Report_Warning
     (Location : GNATdoc.Source_Location;
      Message  : VSS.Strings.Virtual_String);

   procedure Report_Error
     (Location : GNATdoc.Source_Location;
      Message  : VSS.Strings.Virtual_String);

   procedure Report_Internal_Error
     (Location   : GNATdoc.Source_Location;
      Occurrence : Ada.Exceptions.Exception_Occurrence);

   procedure Raise_Not_Implemented
     (Message  : String;
      Location : String := GNAT.Source_Info.Source_Location)
     with No_Return;
   --  Raises GNATdoc.Not_Implemented exception with provided message.

end GNATdoc.Messages;
