------------------------------------------------------------------------------
--                    GNAT Documentation Generation Tool                    --
--                                                                          --
--                       Copyright (C) 2025, AdaCore                        --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;

with Libadalang.Common;

package body GNATdoc.Comments.Extractor.Trailing is

   type Kinds is (None, Subprogram, Parameter, Returns);

   type Entity_Kind is (None, Entity);

   type Entity_Group_Kind is (None, Subprogram);

   type Component_Group_Kind is (None, Parameter, Returns);

   type Entity_Information (Kind : Entity_Kind := None) is record
      Indent  : Libadalang.Slocs.Column_Number := 0;
      Section : GNATdoc.Comments.Section_Access;
   end record;

   type Entity_Group_Information (Kind : Entity_Group_Kind := None) is record
      case Kind is
         when None =>
            null;

         when Subprogram =>
            Indent   : Libadalang.Slocs.Column_Number := 0;
            Sections : Section_Vectors.Vector;
      end case;
   end record;

   type Component_Group_Information
     (Kind : Component_Group_Kind := None) is
   record
      Sections : Section_Vectors.Vector;
   end record;

   type Info is record
      Kind     : Kinds := None;
      Indent   : Libadalang.Slocs.Column_Number := 0;
      Sections : Section_Vectors.Vector;
   end record;

   type Line_Information is record
      Item            : Info;

      Entity          : Entity_Information;
      Component_Group : Component_Group_Information;
      Entity_Group    : Entity_Group_Information;
   end record;

   type Line_Information_Array is
     array (Libadalang.Slocs.Line_Number range <>) of Line_Information;

   generic
      Info : in out Line_Information_Array;

   package Generic_State is

      procedure Initialize;

      procedure Enter_Subprogram
        (Indent   : Libadalang.Slocs.Column_Number;
         Sections : not null access GNATdoc.Comments.Section_Vectors.Vector);

      procedure Leave_Subprogram;

      procedure Mark_Return
        (Start_Line : Libadalang.Slocs.Line_Number;
         End_Line   : Libadalang.Slocs.Line_Number);
      --  Call on Subp_Spec to set location of the return of function, it is
      --  not presented in the tree as node.

      procedure Enter_Parameters_Specification;

      procedure Leave_Parameters_Specification
        (End_Line : Libadalang.Slocs.Line_Number);

      procedure Visit_Defining_Name
        (Line   : Libadalang.Slocs.Line_Number;
         Name   : VSS.Strings.Virtual_String;
         Symbol : VSS.Strings.Virtual_String);

   end Generic_State;

   -------------------
   -- Generic_State --
   -------------------

   package body Generic_State is

      type State_Kind is (None, Subprogram, Parameters_Specification);

      type State_Information (Kind : State_Kind := None) is record
         case Kind is
            when None =>
               null;

            when Parameters_Specification | Subprogram =>
               case Kind is
                  when None =>
                     null;

                  when Parameters_Specification =>
                     null;

                  when Subprogram =>
                     Indent             : Libadalang.Slocs.Column_Number;

                     Section            : not null
                       GNATdoc.Comments.Section_Access;
                     Sections           : not null access
                       GNATdoc.Comments.Section_Vectors.Vector;

                     Component_End_Line : Libadalang.Slocs.Line_Number := 0;

                     Return_Start_Line  : Libadalang.Slocs.Line_Number := 0;
                     Return_End_Line    : Libadalang.Slocs.Line_Number := 0;
               end case;
         end case;
      end record;

      package State_Vectors is
        new Ada.Containers.Vectors (Positive, State_Information);

      Current   : State_Information;
      Enclosing : State_Information;
      Stack     : State_Vectors.Vector;
      Last_Line : Libadalang.Slocs.Line_Number := Info'First;

      procedure Push (New_State : State_Information);

      procedure Pop;

      function Create_Section
        (Sections : in out GNATdoc.Comments.Section_Vectors.Vector;
         Kind     : GNATdoc.Comments.Section_Kind;
         Name     : VSS.Strings.Virtual_String;
         Symbol   : VSS.Strings.Virtual_String)
         return not null GNATdoc.Comments.Section_Access;

      procedure Register
        (Line               : Libadalang.Slocs.Line_Number;
         Component_End_Line : Libadalang.Slocs.Line_Number;
         Kind               : Kinds;
         Section            : not null GNATdoc.Comments.Section_Access);

      --------------------
      -- Create_Section --
      --------------------

      function Create_Section
        (Sections : in out GNATdoc.Comments.Section_Vectors.Vector;
         Kind     : GNATdoc.Comments.Section_Kind;
         Name     : VSS.Strings.Virtual_String;
         Symbol   : VSS.Strings.Virtual_String)
         return not null GNATdoc.Comments.Section_Access is
      begin
         return Result : constant not null GNATdoc.Comments.Section_Access :=
           new GNATdoc.Comments.Section'
             (Kind   => Kind,
              Name   => Name,
              Symbol => Symbol,
              Text   => <>,
              others => <>)
         do
            Sections.Append (Result);
         end return;
      end Create_Section;

      ------------------------------------
      -- Enter_Parameters_Specification --
      ------------------------------------

      procedure Enter_Parameters_Specification is
      begin
         Push ((Kind => Parameters_Specification));
      end Enter_Parameters_Specification;

      ----------------------
      -- Enter_Subprogram --
      ----------------------

      procedure Enter_Subprogram
        (Indent   : Libadalang.Slocs.Column_Number;
         Sections : not null access GNATdoc.Comments.Section_Vectors.Vector) is
      begin
         Push
           ((Kind               => Subprogram,
             Indent             => Indent,
             Return_Start_Line  => <>,
             Return_End_Line    => <>,
             Component_End_Line => <>,
             Section            =>
               Create_Section
                 (Sections => Sections.all,
                  Kind     => GNATdoc.Comments.Raw,
                  Name     => "",
                  Symbol   => "<<CALLABLE>>"),
             Sections           => Sections));
      end Enter_Subprogram;

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize is
      begin
         Info := (others => <>);
      end Initialize;

      ------------------------------------
      -- Leave_Parameters_Specification --
      ------------------------------------

      procedure Leave_Parameters_Specification
        (End_Line : Libadalang.Slocs.Line_Number)
      is
         use type Libadalang.Slocs.Line_Number;

      begin
         if Last_Line /= End_Line then
            Info (End_Line + 1).Component_Group :=
              Info (Last_Line + 1).Component_Group;
            Info (Last_Line + 1).Component_Group := (others => <>);

            Info (End_Line + 1).Entity_Group :=
              Info (Last_Line + 1).Entity_Group;
            Info (Last_Line + 1).Entity_Group := (others => <>);

            Last_Line := End_Line;
         end if;

         Pop;
         Current.Component_End_Line := End_Line;
      end Leave_Parameters_Specification;

      ----------------------
      -- Leave_Subprogram --
      ----------------------

      procedure Leave_Subprogram is
         use type Libadalang.Slocs.Line_Number;

      begin
         if Current.Return_Start_Line /= 0 then
            declare
               Section : constant not null
                 GNATdoc.Comments.Section_Access :=
                   Create_Section
                     (Sections => Current.Sections.all,
                      Kind     => GNATdoc.Comments.Returns,
                      Name     => "",
                      Symbol   => "");

            begin
               Register
                 (Line               => Current.Return_Start_Line,
                  Component_End_Line => Current.Component_End_Line,
                  Kind               => Returns,
                  Section            => Section);

               case Info (Current.Return_Start_Line + 1).Component_Group.Kind
               is
                  when None | Parameter =>
                     Info (Current.Return_Start_Line + 1).Component_Group :=
                       (Kind     => Returns,
                        Sections => <>);
                     Info (Current.Return_Start_Line + 1).Component_Group
                       .Sections.Append (Section);

                  when Returns =>
                     raise Program_Error;
               end case;

               if Last_Line /= Current.Return_End_Line then
                  Info (Current.Return_End_Line + 1).Component_Group :=
                    Info (Last_Line + 1).Component_Group;
                  Info (Last_Line + 1).Component_Group := (others => <>);

                  Info (Current.Return_End_Line + 1).Entity_Group :=
                    Info (Last_Line + 1).Entity_Group;
                  Info (Last_Line + 1).Entity_Group := (others => <>);

                  Last_Line := Current.Return_End_Line;
               end if;

               Current.Component_End_Line := Current.Return_End_Line;
            end;
         end if;

         Pop;
      end Leave_Subprogram;

      -----------------
      -- Mark_Return --
      -----------------

      procedure Mark_Return
        (Start_Line : Libadalang.Slocs.Line_Number;
         End_Line   : Libadalang.Slocs.Line_Number) is
      begin
         Current.Return_Start_Line := Start_Line;
         Current.Return_End_Line   := End_Line;
      end Mark_Return;

      ---------
      -- Pop --
      ---------

      procedure Pop is
      begin
         Current   := Enclosing;
         Enclosing := Stack.Last_Element;
         Stack.Delete_Last;
      end Pop;

      ----------
      -- Push --
      ----------

      procedure Push (New_State : State_Information) is
      begin
         Stack.Append (Enclosing);
         Enclosing := Current;
         Current   := New_State;
      end Push;

      --------------
      -- Register --
      --------------

      procedure Register
        (Line               : Libadalang.Slocs.Line_Number;
         Component_End_Line : Libadalang.Slocs.Line_Number;
         Kind               : Kinds;
         Section            : not null GNATdoc.Comments.Section_Access)
      is
         use type Libadalang.Slocs.Line_Number;

      begin
         --  Move state

         if Last_Line /= Line then
            --  Move components group when there is no gap between end of the
            --  previous components' declaration and processing line.

            if Component_End_Line + 1 = Line
              or Last_Line + 1 = Line
            then
               Info (Line + 1).Component_Group :=
                 Info (Last_Line + 1).Component_Group;
               Info (Last_Line + 1).Component_Group := (others => <>);
            end if;

            Info (Line + 1).Entity_Group :=
              Info (Last_Line + 1).Entity_Group;
            Info (Last_Line + 1).Entity_Group := (others => <>);

            Last_Line := Line;
         end if;

         if Info (Line).Item.Kind = None then
            --  Fill 'atline'

            Info (Line).Item :=
              (Kind     => Kind,
               Indent   => 0,
               Sections => <>);
            Info (Line).Item.Sections.Append (Section);

         elsif Info (Line).Item.Kind = Kind then
            Info (Line).Item.Sections.Append (Section);
         end if;
      end Register;

      -------------------------
      -- Visit_Defining_Name --
      -------------------------

      procedure Visit_Defining_Name
        (Line   : Libadalang.Slocs.Line_Number;
         Name   : VSS.Strings.Virtual_String;
         Symbol : VSS.Strings.Virtual_String)
      is
         use type Libadalang.Slocs.Line_Number;

      begin
         case Current.Kind is
            when None =>
               raise Program_Error;

            when Parameters_Specification =>
               declare
                  Section : constant not null
                    GNATdoc.Comments.Section_Access :=
                      Create_Section
                        (Sections => Enclosing.Sections.all,
                         Kind     => GNATdoc.Comments.Parameter,
                         Name     => Name,
                         Symbol   => Symbol);

               begin
                  Register
                    (Line               => Line,
                     Component_End_Line => Enclosing.Component_End_Line,
                     Kind               => Parameter,
                     Section            => Section);

                  case Info (Line + 1).Component_Group.Kind is
                     when None =>
                        Info (Line + 1).Component_Group :=
                          (Kind     => Parameter,
                           Sections => <>);
                        Info (Line + 1).Component_Group.Sections.Append
                          (Section);

                     when Parameter =>
                        Info (Line + 1).Component_Group.Sections.Append
                          (Section);

                     when Returns =>
                        raise Program_Error;
                  end case;
               end;

            when Subprogram =>
               Register
                 (Line               => Line,
                  Component_End_Line => Current.Component_End_Line,
                  Kind               => Subprogram,
                  Section            => Current.Section);

               --  Fill 'entity'

               Info (Line).Entity :=
                 (Kind    => Entity,
                  Indent  => Current.Indent,
                  Section => Current.Section);

               --  Fill 'entity group'

               Info (Line + 1).Entity_Group :=
                 (Kind     => Subprogram,
                  Indent   => Current.Indent,
                  Sections => <>);
               Info (Line + 1).Entity_Group.Sections.Append (Current.Section);
         end case;
      end Visit_Defining_Name;

   end Generic_State;

   -------------
   -- Process --
   -------------

   procedure Process
     (Node     : Libadalang.Analysis.Basic_Decl'Class;
      Sections : in out GNATdoc.Comments.Section_Vectors.Vector)
   is
      use type Libadalang.Slocs.Line_Number;

      Infos  : Line_Information_Array
        (Node.Sloc_Range.Start_Line .. Node.Sloc_Range.End_Line + 1);
      Subp   : Boolean := False;

      package Visit_State is new Generic_State (Infos);

      function Process_Node
        (Node : Libadalang.Analysis.Ada_Node'Class)
         return Libadalang.Common.Visit_Status;

      ------------------
      -- Process_Node --
      ------------------

      function Process_Node
        (Node : Libadalang.Analysis.Ada_Node'Class)
         return Libadalang.Common.Visit_Status
      is
         procedure Traverse_Children;

         -----------------------
         -- Traverse_Children --
         -----------------------

         procedure Traverse_Children is
            Child : Libadalang.Analysis.Ada_Node;

         begin
            --  LAL: children nodes can be "null", thus the only way to iterate
            --  over children nodes is to use index of the child, and check to
            --  "null" child node to prevent exceptions.

            for J in Node.First_Child_Index .. Node.Last_Child_Index loop
               Child := Node.Child (J);

               if not Child.Is_Null then
                  Child.Traverse (Process_Node'Access);
               end if;
            end loop;
         end Traverse_Children;

         Location     : constant Libadalang.Slocs.Source_Location_Range :=
           Node.Sloc_Range;
         Start_Line   : constant Libadalang.Slocs.Line_Number :=
           Node.Sloc_Range.Start_Line;
         Start_Column : constant Libadalang.Slocs.Column_Number :=
           Node.Sloc_Range.Start_Column;

      begin
         case Node.Kind is
            when Ada_Defining_Name =>
               Visit_State.Visit_Defining_Name
                 (Line   => Start_Line,
                  Name   =>
                     VSS.Strings.To_Virtual_String
                       (Node.As_Defining_Name.F_Name.Text),
                  Symbol =>
                     VSS.Strings.Conversions.To_Virtual_String
                       (Node.As_Defining_Name.F_Name.P_Canonical_Text));

               return Libadalang.Common.Over;

            when Ada_Param_Spec =>
               Visit_State.Enter_Parameters_Specification;
               Traverse_Children;
               Visit_State.Leave_Parameters_Specification (Location.End_Line);

               return Libadalang.Common.Over;

            when Ada_Concrete_Type_Decl =>
               if Node.As_Concrete_Type_Decl.F_Type_Def.Kind
                 /= Ada_Access_To_Subp_Def
               then
                  raise Program_Error;
               end if;

               Visit_State.Enter_Subprogram (Start_Column, Sections'Access);
               Traverse_Children;
               Visit_State.Leave_Subprogram;

               return Libadalang.Common.Over;

            when Ada_Generic_Formal_Type_Decl =>
               if Node.As_Generic_Formal_Type_Decl.F_Decl.As_Formal_Type_Decl
                 .F_Type_Def.Kind
                   /= Ada_Access_To_Subp_Def
               then
                  raise Program_Error;
               end if;

               Visit_State.Enter_Subprogram (Start_Column, Sections'Access);
               Traverse_Children;
               Visit_State.Leave_Subprogram;

               return Libadalang.Common.Over;

            when Ada_Subp_Spec =>
               --  LAL doesn't have node for "return" of the subprogram.

               if not Node.As_Subp_Spec.F_Subp_Returns.Is_Null then
                  declare
                     Token : Libadalang.Common.Token_Reference :=
                       Node.As_Subp_Spec.F_Subp_Returns.Token_Start;

                  begin
                     while Libadalang.Common.Kind
                       (Libadalang.Common.Data (Token)) /= Ada_Return
                     loop
                        Token := Libadalang.Common.Previous (Token);
                     end loop;

                     Visit_State.Mark_Return
                       (Start_Line =>
                          Libadalang.Common.Sloc_Range
                            (Libadalang.Common.Data (Token)).Start_Line,
                        End_Line   => Location.End_Line);
                  end;
               end if;

               Subp := True;
               Traverse_Children;
               Subp := False;

               return Libadalang.Common.Over;

            when Ada_Abstract_Subp_Decl
               | Ada_Entry_Decl
               | Ada_Expr_Function
               | Ada_Generic_Formal_Subp_Decl
               | Ada_Generic_Subp_Internal
               | Ada_Null_Subp_Decl
               | Ada_Subp_Body
               | Ada_Subp_Decl
               | Ada_Subp_Renaming_Decl
            =>
               Visit_State.Enter_Subprogram (Start_Column, Sections'Access);
               Traverse_Children;
               Visit_State.Leave_Subprogram;

               return Libadalang.Common.Over;

            when Ada_Anonymous_Type =>
               if Subp then
                  --  Ignore anonymous types inside Subp_Spec node, they
                  --  might be anonymous access to subprogram type that
                  --  has "nested" subprogram declaration.

                  return Libadalang.Common.Over;
               end if;

            when others =>
               null;
         end case;

         return Libadalang.Common.Into;
      end Process_Node;

   begin
      Visit_State.Initialize;

      Node.Traverse (Process_Node'Access);

      declare
         use type Libadalang.Slocs.Column_Number;
         use type VSS.Strings.Character_Count;
         use type VSS.Strings.Virtual_String;

         type State_Kind is
           (None, Atline, Components_Group, Entities_Group);

         Token     : Libadalang.Common.Token_Reference := Node.Token_Start;
         Location  : Libadalang.Slocs.Source_Location_Range;

         Last_Line : Libadalang.Slocs.Line_Number      := 0;

         Text      : VSS.String_Vectors.Virtual_String_Vector;
         Line      : VSS.Strings.Virtual_String;
         Sections  : GNATdoc.Comments.Section_Vectors.Vector;

         State         : State_Kind := None;
         Atline_Indent : VSS.Strings.Character_Count := 0;

         Entity_Line           : Libadalang.Slocs.Line_Number := 0;
         Components_Group_Line : Libadalang.Slocs.Line_Number := 0;
         Entities_Group_Line   : Libadalang.Slocs.Line_Number := 0;

         procedure Apply;

         procedure Update (Location : Libadalang.Slocs.Source_Location_Range);

         -----------
         -- Apply --
         -----------

         procedure Apply is
            Indent : constant VSS.Strings.Character_Count :=
              Count_Leading_Whitespaces (Text.First_Element);

         begin
            --  Remove leading whitespaces

            for Line in Text.First_Index .. Text.Last_Index loop
               Text.Replace
                 (Line, Remove_Leading_Whitespaces (Text (Line), Indent));
            end loop;

            --  Append extracted text to sections

            for Section of Sections loop
               if not Section.Text.Is_Empty then
                  Section.Text.Append (VSS.Strings.Empty_Virtual_String);
               end if;

               Section.Text.Append (Text);
            end loop;

            Sections.Clear;
            Text.Clear;
            Last_Line := 0;
            State := None;
            Atline_Indent := 0;
         end Apply;

         ------------
         -- Update --
         ------------

         procedure Update
           (Location : Libadalang.Slocs.Source_Location_Range) is
         begin
            for Line in Location.Start_Line + 1 .. Location.End_Line
            loop
               if Line in Infos'Range then
                  if Infos (Line).Entity.Kind /= None then
                     Entities_Group_Line := 0;
                     Entity_Line         := Line;
                  end if;

                  if Infos (Line).Entity_Group.Kind /= None then
                     Entities_Group_Line := Line;
                     Entity_Line         := 0;
                  end if;

                  if Infos (Line).Component_Group.Kind /= None then
                     Components_Group_Line := Line;
                  end if;
               end if;
            end loop;
         end Update;

      begin
         if Infos (Infos'First).Entity.Kind /= None then
            Entity_Line := Infos'First;
         end if;

         if Infos (Infos'First).Component_Group.Kind /= None then
            Components_Group_Line := Infos'First;
         end if;

         if Infos (Infos'First).Entity_Group.Kind /= None then
            Entities_Group_Line := Infos'First;
         end if;

         loop
            exit when Token = Libadalang.Common.No_Token;

            Location :=
              Libadalang.Common.Sloc_Range (Libadalang.Common.Data (Token));

            <<Redo>>

            case Libadalang.Common.Kind (Libadalang.Common.Data (Token)) is
               when Ada_Whitespace =>
                  case State is
                     when None =>
                        if Location.End_Line = Location.Start_Line then
                           null;

                        elsif Location.Start_Line + 1 = Location.End_Line then
                           Update (Location);

                        else
                           Update (Location);

                           exit when Location.End_Line > Infos'Last;
                        end if;

                     when Atline =>
                        if Location.Start_Line = Location.End_Line then
                           null;

                        elsif Last_Line + 1 = Location.End_Line then
                           if Infos (Location.End_Line).Item.Kind /= None then
                              Apply;
                           end if;

                           Update (Location);

                        else
                           Apply;
                           Update (Location);

                           exit when Location.End_Line > Infos'Last;
                        end if;

                     when Components_Group =>
                        if Location.Start_Line = Location.End_Line then
                           null;

                        elsif Last_Line + 1 = Location.End_Line then
                           if Infos (Location.End_Line).Item.Kind /= None then
                              Apply;
                           end if;

                           Update (Location);

                        else
                           Apply;
                        end if;

                     when Entities_Group =>
                        if Location.End_Line = Location.Start_Line then
                           null;

                        elsif Last_Line + 1 = Location.End_Line then
                           Update (Location);

                        else
                           Apply;

                           exit;
                        end if;
                  end case;

               when Ada_Comment =>
                  declare
                     Comment  : constant VSS.Strings.Virtual_String :=
                       VSS.Strings.To_Virtual_String
                         (Libadalang.Common.Text (Token));
                     Iterator :
                       VSS.Strings.Character_Iterators.Character_Iterator :=
                         Comment.At_First_Character;
                     Success  : Boolean with Unreferenced;

                  begin
                     Success := Iterator.Forward;
                     Success := Iterator.Forward;

                     Line :=
                       (VSS.Strings.Character_Count
                          (Location.Start_Column + 1) * ' '
                        & Comment.Tail_From (Iterator));
                  end;

                  case State is
                     when None =>
                        if Location.Start_Line in Infos'Range
                          and then
                            Infos (Location.Start_Line).Item.Kind /= None
                        then
                           State         := Atline;
                           Sections      :=
                             Infos (Location.Start_Line).Item.Sections;
                           Atline_Indent := Count_Leading_Whitespaces (Line);
                           Text.Append (Line);

                        else
                           if Components_Group_Line /= 0 then
                              if (Entity_Line /= 0
                                  and then Location.Start_Column
                                  > Infos (Entity_Line).Entity.Indent)
                                or (Entities_Group_Line /= 0
                                      and then Location.Start_Column
                                    > Infos (Entities_Group_Line)
                                        .Entity_Group.Indent)
                              then
                                 State    := Components_Group;
                                 Sections :=
                                   Infos (Components_Group_Line)
                                     .Component_Group.Sections;
                                 Text.Append (Line);
                              end if;
                           end if;

                           if Entity_Line /= 0 then
                              if Location.Start_Column
                                = Infos (Entity_Line).Entity.Indent
                              then
                                 raise Program_Error;
                              end if;
                           end if;

                           if Entities_Group_Line /= 0 then
                              if Location.Start_Column
                                = Infos (Entities_Group_Line)
                                    .Entity_Group.Indent
                              then
                                 State         := Entities_Group;
                                 Sections      :=
                                   Infos (Entities_Group_Line)
                                     .Entity_Group.Sections;
                                 Text.Append (Line);
                              end if;
                           end if;
                        end if;

                     when Atline =>
                        if Location.Start_Line in Infos'Range
                          and then
                            Infos (Location.Start_Line).Item.Kind /= None
                        then
                           Apply;

                           goto Redo;

                        elsif Count_Leading_Whitespaces (Line) < Atline_Indent
                        then
                           Apply;

                           goto Redo;

                        else
                           Text.Append (Line);
                        end if;

                     when Components_Group =>
                        if (Entity_Line /= 0
                            and then Location.Start_Column
                            > Infos (Entity_Line).Entity.Indent)
                          or (Entities_Group_Line /= 0
                              and then Location.Start_Column
                              > Infos (Entities_Group_Line)
                              .Entity_Group.Indent)
                        then
                           Text.Append (Line);

                        else
                           Apply;

                           goto Redo;
                        end if;

                     when Entities_Group =>
                        if Infos (Entities_Group_Line).Entity_Group.Indent
                          = Location.Start_Column
                        then
                           Text.Append (Line);

                        else
                           raise Program_Error;
                        end if;
                  end case;

                  Last_Line := Location.Start_Line;

               when others =>
                  null;
            end case;

            Token := Libadalang.Common.Next (@);
         end loop;

         if State /= None then
            raise Program_Error;
         end if;
      end;
   end Process;

end GNATdoc.Comments.Extractor.Trailing;
