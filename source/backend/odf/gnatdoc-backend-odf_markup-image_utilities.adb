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

with Ada.Unchecked_Deallocation;
with GNAT.Strings;

with VSS.Strings.Conversions;
with VSS.Strings.Converters.Decoders;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;

with GNATCOLL.Coders.Base64;

with GNATdoc.Messages;

package body GNATdoc.Backend.ODF_Markup.Image_Utilities is

   type Stream_Element_Array_Access is
     access all Ada.Streams.Stream_Element_Array;

   procedure Free is
     new Ada.Unchecked_Deallocation
           (Ada.Streams.Stream_Element_Array, Stream_Element_Array_Access);

   Image_Directories : GNATdoc.Virtual_File_Vectors.Vector;

   Not_Found_Template : constant
     VSS.Strings.Templates.Virtual_String_Template :=
       "image file '{}' is not found";

   -----------------
   -- Load_Encode --
   -----------------

   procedure Load_Encode
     (Destination     : VSS.Strings.Virtual_String;
      Encoded_Content : out VSS.Strings.Virtual_String)
   is
      use type Ada.Streams.Stream_Element_Offset;

      Name    : constant GNATCOLL.VFS.Filesystem_String :=
        GNATCOLL.VFS.Filesystem_String
          (VSS.Strings.Conversions.To_UTF_8_String (Destination));
      File    : GNATCOLL.VFS.Virtual_File;
      Binary  : GNAT.Strings.String_Access;
      Encoded : Stream_Element_Array_Access;
      Coder   : GNATCOLL.Coders.Base64.Encoder_Type;

   begin
      for Directory of Image_Directories loop
         File :=
           GNATCOLL.VFS.Create_From_Base
             (Base_Name => Name,
              Base_Dir  => Directory.Full_Name.all);

         exit when File.Is_Regular_File;
      end loop;

      if not File.Is_Regular_File then
         GNATdoc.Messages.Report_Warning
           (Not_Found_Template.Format
              (VSS.Strings.Formatters.Strings.Image (Destination)));

         return;
      end if;

      Binary := File.Read_File;
      Encoded := new Ada.Streams.Stream_Element_Array (1 .. Binary'Length * 2);

      declare
         Binary_Data : Ada.Streams.Stream_Element_Array (1 .. Binary'Length)
           with Import, Address => Binary.all'Address;
         In_Last     : Ada.Streams.Stream_Element_Count;
         Out_Last    : Ada.Streams.Stream_Element_Count;
         Decoder     : VSS.Strings.Converters.Decoders.Virtual_String_Decoder;

      begin
         Coder.Initialize;
         Coder.Transcode
           (In_Data  => Binary_Data,
            In_Last  => In_Last,
            Out_Data => Encoded.all,
            Out_Last => Out_Last,
            Flush    => GNATCOLL.Coders.Finish);

         Decoder.Initialize
           ("ISO-8859-1",
            [VSS.Strings.Converters.Stateless => True, others => False]);
         Encoded_Content :=
           Decoder.Decode (Encoded (Encoded'First .. Out_Last));
      end;

      Free (Encoded);
      GNAT.Strings.Free (Binary);
   end Load_Encode;

   ---------------------------
   -- Set_Image_Directories --
   ---------------------------

   procedure Set_Image_Directories
     (To : GNATdoc.Virtual_File_Vectors.Vector) is
   begin
      Image_Directories := To;
   end Set_Image_Directories;

end GNATdoc.Backend.ODF_Markup.Image_Utilities;
