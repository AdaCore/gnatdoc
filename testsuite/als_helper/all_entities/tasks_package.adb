
with Tasks;

package body Tasks_Package is

   TO : Tasks.Task_Type;

   task Requeue_Task is
      entry Requeue_To_Object;
      entry Requeue_To_Type;
   end Requeue_Task;

   task body Requeue_Task is
   begin
      accept Requeue_To_Object do
         requeue Tasks.Task_Object.Task_Requeue_Entry;
      end Requeue_To_Object;

      accept Requeue_To_Type do
         requeue TO.Task_Requeue_Entry;
      end Requeue_To_Type;
   end Requeue_Task;

   procedure Dummy is
   begin
      Tasks.Task_Object.Task_Entry;
      TO.Task_Entry;
   end Dummy;

end Tasks_Package;
