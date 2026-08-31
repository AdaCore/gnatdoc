
package body Tasks is

   task body Task_Object is

      --  Description of the task object (body).

   begin
      accept Task_Entry;
      --  Description of the task entry (body).

      accept Task_Requeue_Entry do
      --  Description of the task requeue entry (body).

         requeue Task_Entry;
      end Task_Requeue_Entry;
   end Task_Object;

   task body Task_Type is

      --  Description of the task type (body).

   begin
      accept Task_Entry do
      --  Description of the task entry (body).

         requeue Task_Requeue_Entry;
      end Task_Entry;

      accept Task_Requeue_Entry do
      --  Description of the task requeue entry (body).

         requeue Task_Object.Task_Requeue_Entry;
      end Task_Requeue_Entry;
   end Task_Type;

   TO : Task_Type;

begin
   Task_Object.Task_Entry;
   TO.Task_Entry;
end Tasks;
