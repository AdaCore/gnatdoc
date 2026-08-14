package Sample is

   type Kind is (Alpha, Beta);
   --  Kind description
   --  @value Alpha
   --    Alpha value
   --  @value Beta
   --    Beta value

   type Rec is record
      Value : Integer;
      --  Value field
   end record;
   --  Record description

   function Identity (Input : Integer) return Integer;
   --  Identity function
   --  @param Input
   --    Input value
   --  @return
   --    Same value

   function Tag_Only (Input : Integer) return Integer;
   --  @param Input
   --    Tag-only input value
   --  @return
   --    Tag-only result

   procedure Raises_Only;
   --  @exception Constraint_Error
   --    Raised when constraints are violated

   function Mention_Exclude return Boolean;
   --  Return True when entity is marked by `@exclude` tag

   type Legacy_Enum is
     (Legacy_A,
      Legacy_B,
      Legacy_C);
   --  @enum Legacy_A
   --    Legacy A description
   --  @enum Legacy_B
   --    Legacy B description
   --  @enum Legacy_C
   --    Legacy C description

end Sample;