
--  GNATdoc supports two styles of locations for documentation comments
--   * leading: the documentation comments are placed before entities
--   * GNAT (trailing): the documentation comments are placed after the
--     entities
--
--  In all styles, documentation comments must not be separated from the entity
--  declaration by an empty line.
--
--  This package shows how comments should be written when the leading style
--  is used.
--
--  The documentation for composite entities should contain the documentation
--  for the entity, and the documentation for elements composing the entity.
--
--  The documentation for an entity should have same indentation as the
--  entity declaration. Any comments with deeper indentation are processed as
--  documentation of elements composing the entity.
--
--  These elements can be documented in few ways:
--   * a comment on the line of the element's identifier
--   * a comment on the line immediately below the element's declaration, in
--     which case comments on the following lines are considered as
--     continuation of the documentation
--   * using the corresponding GNATdoc tags in the documentation of the entity
--     itself
--
--  All comments preceding a declaration are considered part of the
--  documentation, stopping at the first blank or non-comment line.

package Style_Leading_Composite is

   --  Enumeration type has description of the type and description of
   --  individual enumeration literals.
   --
   --  @enum Item_3 Enumeration literal's description using GNATdoc's tag in
   --  the documentation of the enumeration type.
   type Enumeration_Type is
     (Item_1,  --  Enumeration literal's description at the declaration line
      --  Enumeration literal's description below declaration line
      Item_2,
      Item_3);

   --  Record type has description of the type and description of individual
   --  components.
   --
   --  @field Component_3 Record component's description using GNATdoc's tag in
   --  the documentation of the record type.
   type Record_Type is record
      Component_1 : Integer;  --  Record component's description.
      --  Record component's description below the line of declaration.
      Component_2 : Integer;
      Component_3 : Integer;
   end record;

   --  All subprograms, including procedures, has description of the subprogram,
   --  description of parameters, and description of raised exceptions.
   --
   --  @param Z Subprogram parameter's description using GNATdoc's tag in the
   --  documentation of the subprogram.
   --  @exception Constraint_Error Description of conditions when an exception
   --  can be raised by the subprogram.
   procedure Do_Something
     (X : Integer;  --  Subprogram parameter's description at the line.
      --  Subprogram parameter's description below declaration line.
      Y : Integer;
      Z : Integer);

   --  In addition to procedures, function has description of the return
   --  value.
   --
   --  @return Description of return value of the function with GNATdoc's tag.
   function Compute_Something_1 (X : Integer) return Integer;

   --  Just another way to describe return value.
   function Compute_Something_2
     return Integer;  --  Description of the return value at the line of return.

end Style_Leading_Composite;
