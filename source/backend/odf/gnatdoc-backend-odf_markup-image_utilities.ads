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

package GNATdoc.Backend.ODF_Markup.Image_Utilities is

   procedure Load_Encode
     (Destination     : VSS.Strings.Virtual_String;
      Encoded_Content : out VSS.Strings.Virtual_String);
   --  Loads given file, converts its content into Base64 encoded form and
   --  transforms to `Virtual_String`.

   procedure Set_Image_Directories (To : GNATdoc.Virtual_File_Vectors.Vector);
   --  Set list of directories to lookup for image files.

end GNATdoc.Backend.ODF_Markup.Image_Utilities;
