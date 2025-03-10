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

with GNATdoc.Messages;

package GNATdoc.Comments.Undocumented_Checker is

   procedure Check_Undocumented
     (Location      : GNATdoc.Source_Location;
      Name          : VSS.Strings.Virtual_String;
      Documentation : GNATdoc.Comments.Structured_Comment;
      Messages      : in out GNATdoc.Messages.Message_Container);
   --  Check presense of the documentation for all components and report
   --  warnings when necessary.

end GNATdoc.Comments.Undocumented_Checker;
