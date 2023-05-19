------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                     Copyright (C) 2022-2023, AdaCore                     --
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

--  Proxy to provide information from structured comment to XML templates
--  processor.

with VSS.Strings;
with VSS.XML.Templates.Proxies;

package GNATdoc.Comments.Proxies is

   type Structured_Comment_Proxy is limited
     new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy
       with private;

   function Create
     (Documentation : Structured_Comment_Access)
      return Structured_Comment_Proxy'Class;

private

   type Structured_Comment_Proxy is limited
     new VSS.XML.Templates.Proxies.Abstract_Composite_Proxy
   with record
      Sections : Section_Vectors.Vector;
   end record;

   overriding function Component
     (Self : in out Structured_Comment_Proxy;
      Name : VSS.Strings.Virtual_String)
      return VSS.XML.Templates.Proxies.Abstract_Proxy'Class;

end GNATdoc.Comments.Proxies;
