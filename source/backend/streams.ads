------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2022, AdaCore                        --
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

with GNATCOLL.VFS;

with VSS.Text_Streams;
private with VSS.Text_Streams.File_Output;

package Streams is

   type Output_Text_Stream is
     limited new VSS.Text_Streams.Output_Text_Stream with private;

   procedure Open
     (Self : in out Output_Text_Stream'Class;
      File : GNATCOLL.VFS.Virtual_File);

   procedure Close (Self : in out Output_Text_Stream'Class);

private

   type Output_Text_Stream is
     limited new VSS.Text_Streams.File_Output.File_Output_Text_Stream with
       null record;

end Streams;
