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

with VSS.String_Vectors;
with VSS.XML.Event_Vectors;

package GNATdoc.Backend.ODF_Markup is

   function Build_Markup
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.XML.Event_Vectors.Vector;

   function Build_Code_Snipped_Markup
     (Text : VSS.String_Vectors.Virtual_String_Vector)
      return VSS.XML.Event_Vectors.Vector;

end GNATdoc.Backend.ODF_Markup;
