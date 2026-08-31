
with Tasks;

package body Tasks_Package is

   TO : Tasks.Task_Type;

   procedure Dummy is
   begin
      Tasks.Task_Object.Task_Entry;
      TO.Task_Entry;
   end Dummy;

end Tasks_Package;
