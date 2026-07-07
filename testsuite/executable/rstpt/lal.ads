with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Unchecked_Deallocation;

package LAL is

   Default_Charset : constant String := "iso-8859-1";
   --  Default charset

   Exclude_Value : constant String := "iso-8859-1";
   --  Default charset
   --  @exclude-value

   Multiline_Value : constant String :=
     "this is first line of the multiline initialization expression"
     & " and this is second line of it";
   --  Multiline initialization expression

   File_Read_Error : exception;
   --  Exception

   type Ada_Node is tagged private;
   --  Root of node hierarchy

   type Basic_Decl is new Ada_Node with private;
   --  Basic declaration

   No_Ada_Node : constant Ada_Node;
   --  Null node.

   No_Basic_Decl : constant Basic_Decl;
   --  @private

   type Ada_Node_Array is array (Positive range <>) of Ada_Node;
   --  Array of nodes

   function Parent (Self : Ada_Node'Class) return Ada_Node;
   --  Parent node

   function Children (Self : Ada_Node'Class) return Ada_Node_Array;
   --  Children nodes

   package Elementary_Functions is
     new Ada.Numerics.Generic_Elementary_Functions (Float);
   --  Instantiation of the generic package

   type Ada_Node_Array_Access is access all Ada_Node_Array;
   --  Access to array type

   procedure Free is
     new Ada.Unchecked_Deallocation (Ada_Node_Array, Ada_Node_Array_Access);
   --  Not included into documentation

   type Record_Type (X : Integer) is record
      Y : Integer;
      --  Component Y

      Z : access constant Integer;
      --  Component Z

      W : not null access constant Integer;
      --  Component W
   end record;
   --  Description of the Record_Type

   function GNATdoc_179 (Source : Ada_Node'Class) return Ada_Node'Class;
   --  eng/ide/gnatdoc#179
   --  Types of parameters and return contains `'Class`

   function GNATdoc_180
     (F : not null access function (N : Ada_Node'Class) return Boolean)
      return access procedure (N : Ada_Node);
   --  eng/ide/gnatdoc#180
   --  Access to subprogram as type of subprogram's parameter and return value.

   VMap_GNATdoc_180 : array (Boolean) of Boolean;
   --  eng/ide/gnatdoc#180
   --  Anonymous array type

   CMap_GNATdoc_180 : constant array (Boolean) of Boolean := (True, False);
   --  eng/ide/gnatdoc#180
   --  Anonymous array type

   package Num renames Ada.Numerics;
   --  eng/ide/gnatdoc#183
   --  Rename of the package

private

   type Ada_Node is tagged null record;

   type Basic_Decl is new Ada_Node with null record;

   No_Ada_Node : constant Ada_Node := (others => <>);
   No_Basic_Decl : constant Basic_Decl := (others => <>);

end LAL;
