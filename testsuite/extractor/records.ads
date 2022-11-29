
with System.Storage_Elements;

with All_Enumerations;

package Records is

   type Record_Type_1 (A : Boolean) is record
      X : Integer with Atomic, Volatile;
   end record;
   --  Record type with discriminant
   --
   --  @field A Discriminant
   --  @field X Value of X

   type Record_Type_2
     (K : All_Enumerations.Enumeration_Type_1) is   --  Description of the discriminant
   record
      case K is
         when All_Enumerations.A | All_Enumerations.B =>
            --  Case of A | B (should not be included into documentation.
            X : Integer;  --  This is decsription of X component.

            case K is
               when All_Enumerations.A =>
                  null;
                  --  Should not be included

               when All_Enumerations.B =>
                  Y : Integer;  --  This is description of Y component.

               when others =>
                  null;
            end case;

         when All_Enumerations.C =>
            Z : Integer;
      end case;
   end record;
   --  This is complex declaration of the record type with discriminants and
   --  alternatives.
   --
   --  @field Z  Description of the Z member

   ------------------------------
   -- String_Data from the VSS --
   ------------------------------

   type Character_Offset is range -2 ** 30 .. 2 ** 30 - 1;
   subtype Character_Count is Character_Offset
     range 0 .. Character_Offset'Last;

   type Abstract_String_Handler is limited interface;

   type String_Handler_Access is access all Abstract_String_Handler'Class;

   type String_Data (In_Place : Boolean := False) is record
      Capacity : Character_Count := 0;

      Padding  : Boolean := False;
      --  This padding bit is not used in the code, but here for the benefit
      --  of dynamic memory analysis tools such as valgrind.

      case In_Place is
         when True =>
            Storage : System.Storage_Elements.Storage_Array (0 .. 19);

         when False =>
            Handler : String_Handler_Access;
            Pointer : System.Address;
      end case;
   end record;
   for String_Data use record
      Storage  at 0  range  0 .. 159;
      Handler  at 0  range  0 ..  63;
      Pointer  at 8  range  0 ..  63;
      Capacity at 20 range  0 ..  29;
      Padding  at 20 range 30 ..  30;
      In_Place at 20 range 31 ..  31;
   end record;
   --  String_Data is a pair of Handler and pointer to the associated data.
   --  It is not defined how particular implementation of the String_Handler
   --  use pointer.
   --
   --  However, there is one exception: when In_Place Flag is set it means
   --  that special predefined handler is used to process Storage.
   --
   --  Note: data layout is optimized for x86-64 CPU.
   --  Note: Storage has 4 bytes alignment.

   --------------
   -- VB28-014 --
   --------------

   type My_Type is record
      A : Integer;
      --  This is a comment for A
      B : Integer;
      --  This is a comment for B
   end record;
   --  Comments for both fields must be extracted from the comments around.

end Records;
