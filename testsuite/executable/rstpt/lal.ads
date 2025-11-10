with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Unchecked_Deallocation;

package LAL is

   Default_Charset : constant String := "iso-8859-1";
   --  Default charset

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

private

   type Ada_Node is tagged null record;

   type Basic_Decl is new Ada_Node with null record;

   No_Ada_Node : constant Ada_Node := (others => <>);
   No_Basic_Decl : constant Basic_Decl := (others => <>);

end LAL;
