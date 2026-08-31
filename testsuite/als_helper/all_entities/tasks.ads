
package Tasks is

   task Task_Object is

      --  Description of the task object (specification).

      entry Task_Entry;
      --  Description of the task entry (specification).

      entry Task_Requeue_Entry;
      --  Description of the task requeue entry (specification).

      entry Task_Entry_Family (Positive range 1 .. 10);
      --  Description of the task entry family (specification).

   end Task_Object;

   task type Task_Type is

      --  Description of the task type (specification).

      entry Task_Entry;
      --  Description of the task entry (specification).

      entry Task_Requeue_Entry;
      --  Description of the task requeue entry (specification).

      entry Task_Entry_Family (Positive range 1 .. 10);
      --  Description of the task entry family (specification).

   end Task_Type;

   task Separate_Task_Object is

      --  Description of the separate task object (specification).

      entry Separate_Task_Entry;
      --  Description of the separate task entry (specification).

   end Separate_Task_Object;

   task type Separate_Task_Type is

      --  Description of the separate task type (specification).

      entry Separate_Task_Entry;
      --  Description of the separate task entry (specification).

   end Separate_Task_Type;

end Tasks;
