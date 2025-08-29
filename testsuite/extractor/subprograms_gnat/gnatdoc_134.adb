with Ada.Text_IO; use Ada.Text_IO;
--  with Ada.Text_IO;
--  with Test

procedure GNATdoc_134 is
   Start_Idx : Integer := 0;

   type My_Rec is record
      A, B : Integer := 10;
   end record;

   type My_Second_Rec is record
      C, D : My_Rec;
   end record;

   procedure Zboob (arguments : Integer) is begin
      Ada.Text_IO.Put_Line (arguments'Img);
   end Zboob;

   obj_1 : My_Rec;
   Obj_2 : My_Second_Rec;
begin
   Start_Idx := Start_Idx + 1;
   Zboob (Start_Idx);
end GNATdoc_134;
