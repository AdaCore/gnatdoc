package Concrete_Types is

    type Parent_Type is abstract tagged limited private;

    type Child_Type is abstract new Parent_Type with null record;

    type Great_Child_Type is new Text_Document with record
        Field_One : Integer;
        --  A simple integer field.
    end record;

    type int is new Integer;

end Concrete_Types;
