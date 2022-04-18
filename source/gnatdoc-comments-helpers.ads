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

private with Ada.Containers.Vectors;

private with Langkit_Support.Slocs;

private with VSS.String_Vectors;
with VSS.Strings;

package GNATdoc.Comments.Helpers is

   function Get_Subprogram_Description
     (Self       : Structured_Comment'Class;
      Terminator : VSS.Strings.Line_Terminator := VSS.Strings.LF)
      return VSS.Strings.Virtual_String;
   --  Return text of the description subprogram as single string using given
   --  line terminator. Text includes description of the subprogram,
   --  description of the parameters, return value and raised exceptions.
   --
   --  Convenience function for ALS.

   function Get_Subprogram_Parameter_Description
     (Self       : Structured_Comment'Class;
      Symbol     : VSS.Strings.Virtual_String;
      Terminator : VSS.Strings.Line_Terminator := VSS.Strings.LF)
      return VSS.Strings.Virtual_String;
   --  Return text of the description subprogram as single string using given
   --  line terminator. Text includes description of the subprogram,
   --  description of the parameters, return value and raised exceptions.
   --
   --  Convenience function for ALS.

end GNATdoc.Comments.Helpers;
