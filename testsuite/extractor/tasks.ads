
--  Test extraction of the documentation for tasks and task types.
--  Note, documentation extraction code is almost common for subprograms and
--  entries, thus, number of test cases for entries are minimal to check that
--  it works and cover entries specific cases.

package Tasks is

   type IE is synchronized interface;

   type IP is synchronized interface;

   not overriding procedure Process (Self : IP) is abstract;

   task T_Entryless_Empty_Trailing;
   --  This is trailing section of description of the task
   --  T_Entryless_Empty_Trailing.

   --  This is leading section of the description of the task
   --  T_Entryless_Leading.
   task T_Entryless_Leading is
   end T_Entryless_Leading;

   task T_Entryless_Intermediate is
      --  This is intermediate section of the description of the task
      --  T_Entryless_Intermediate.
   end T_Entryless_Intermediate;

   --  This is leading section of the description of the task
   --  T_Entryless_Inherited_Leading
   task T_Entryless_Inherited_Leading is new IE with
   end T_Entryless_Inherited_Leading;

   task T_Entryless_Inherited_Intermediate is new IE with
      --  This is intermediate section of the description of the task
      --  T_Entryless_Inherited_Intermediate.
   end T_Entryless_Inherited_Intermediate;

   task T_1 is
      entry E;
      --  Trailing comment for the entry
   end T_1;

   task T_2 is
      --  Leading comment for the entry
      entry E;
   end T_2;

   task T_3 is
      entry E;
      --  Trailing comment for the entry
   end T_3;

   task type TT_Entryless_Empty_Trailing;
   --  This is trailing section of description of the task
   --  TT_Entryless_Empty_Trailing.

   --  This is leading section of the description of the task
   --  TT_Entryless_Leading.
   task type TT_Entryless_Leading is
   end TT_Entryless_Leading;

   task type TT_Entryless_Intermediate is
      --  This is intermediate section of the description of the task
      --  TT_Entryless_Intermediate.
   end TT_Entryless_Intermediate;

   --  This is leading section of the description of the task
   --  TT_Entryless_Inherited_Leading
   task type TT_Entryless_Inherited_Leading is new IE with
   end TT_Entryless_Inherited_Leading;

   task type TT_Entryless_Inherited_Intermediate is new IE with
      --  This is intermediate section of the description of the task
      --  TT_Entryless_Inherited_Intermediate.
   end TT_Entryless_Inherited_Intermediate;

   task type TT_1 is
      entry E;
      --  Trailing comment for the entry
   end TT_1;

   task type TT_2 is
      --  Leading comment for the entry
      entry E;
   end TT_2;

   task type TT_3 is
      entry E;
      --  Trailing comment for the entry
   end TT_3;

end Tasks;
