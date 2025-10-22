
package Discriminant_Record_Types is

   type Discriminant_Null_Record (Discriminant : Integer) is null record;
   --  Description of the `Discriminant_Null_Record` type.
   --
   --  @field Discriminant Description of the discriminant

   type Unknown_Discriminant_Private_Null_Record (<>) is private;
   --  Public description of the `Unknown_Discriminant_Private_Null_Record`
   --  type.

   type Known_Discriminant_Private_Null_Record (Discriminant : Integer)
     is private;
   --  Public description of the `Known_Discriminant_Private_Null_Record` type.
   --
   --  @field Discriminant Public description of the discriminant

   type Incomplete_Discriminant_Null_Record;
   --  Incomplete description of the `Incomplete_Discriminant_Null_Record`
   --  type.

   type Incomplete_Discriminant_Null_Record (Discriminant : Integer)
     is null record;
   --  Description of the `Incomplete_Discriminant_Null_Record` type.
   --
   --  @field Discriminant Description of the discriminant

   type Incomplete_Unknown_Discriminant_Private_Null_Record;
   --  Incomplete description of the
   --  `Incomplete_Unknown_Discriminant_Private_Null_Record` type.

   type Incomplete_Unknown_Discriminant_Private_Null_Record (<>) is private;
   --  Public description of the
   --  `Incomplete_Unknown_Discriminant_Private_Null_Record` type.

   type Incomplete_Known_Discriminant_Private_Null_Record;
   --  Incomplete description of the
   --  `Incomplete_Known_Discriminant_Private_Null_Record` type.

   type Incomplete_Known_Discriminant_Private_Null_Record
          (Discriminant : Integer) is private;
   --  Public description of the
   --  `Incomplete_Known_Discriminant_Private_Null_Record` type.
   --
   --  @field Discriminant Public description of the discriminant

private

   type Unknown_Discriminant_Private_Null_Record (Discriminant : Integer)
     is null record;
   --  Private description of the `Unknown_Discriminant_Private_Null_Record`
   --  type.
   --
   --  @field Discriminant Description of the discriminant

   type Known_Discriminant_Private_Null_Record (Discriminant : Integer)
     is null record;
   --  Private description of the `Known_Discriminant_Private_Null_Record`
   --  type.
   --
   --  @field Discriminant Private description of the discriminant

   type Incomplete_Unknown_Discriminant_Private_Null_Record
          (Discriminant : Integer) is null record;
   --  Private description of the
   --  `Incomplete_Unknown_Discriminant_Private_Null_Record` type.
   --
   --  @field Discriminant Description of the discriminant

   type Incomplete_Known_Discriminant_Private_Null_Record
          (Discriminant : Integer) is null record;
   --  Private description of the
   --  `Incomplete_Known_Discriminant_Private_Null_Record` type.
   --
   --  @field Discriminant Private description of the discriminant

   procedure Dummy;

end Discriminant_Record_Types;