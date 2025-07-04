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

with VSS.XML.Event_Vectors;
with VSS.XML.Templates.Proxies;
with VSS.XML.Templates.Values;

private package GNATdoc.Proxies is

   type Markup_Proxy is
     limited new VSS.XML.Templates.Proxies.Abstract_Value_Proxy with
   record
      Markup : VSS.XML.Event_Vectors.Vector;
   end record;

   overriding function Value
     (Self : Markup_Proxy) return VSS.XML.Templates.Values.Value;

end GNATdoc.Proxies;
