***********************
Annotating source files
***********************

GNATdoc extracts documentation directly from the comments present in source
files for your project. Special tags present in the comments are interpreted
by GNATdoc.

Documentation is extracted from the comment blocks at different locations,
depending of the entity kind and documentation style. The description below
provides a list of all supported blocks for each entity kind.


Documenting packages
--------------------

The documentation attached to each package is the block of comment from one of
the following locations:

* directly preceeding context clauses

* directly preceeding the package declaration

* directly following 'is' keyword of the package declaration

* directly following the block of 'pragma' directives and 'use' context
   clauses at the beginning of the package declaration

For example::

  --  Copyright (C) COPYRIGHT HOLDER

  --  This package provides routines for drawing basic shapes and Bézier curves.

  package Drawing is


Documenting enumeration types
-----------------------------

The documentation attached to each enumeration type is the block of comment
directly preceding, or directly following, the enumeration type declaration; it should
have the same indentation as the enumeration type declaration, to distinguish it from
the multiline in line documentation of the enumeration literal itself.

The following tag is supported when annotating enumeration literals:

*@enum*

   document an enumeration literal, with the following syntax:

      *@enum <enumeration_literal> <description>*

   where:

      *<enumeration_literal>*

        is the value of the enumeration literal as it appears in the
        enumeration type declaration.

      *<description>*

        the documentation for the enumeration literal; all following text
        is considered for inclusion, until another tag or end of comment block
        is encountered.

For example::

  --  Colors supported by this drawing application
  --  @enum Black The black color is the default color of the pen
  --  @enum White The white color is the default color of the background
  --  @enum Green The green color is the default color of the border
  type Colors is (Black, White, Green);

Enumeration literals can also be documented inline, with the documentation for
each literal directly following its declaration (or directly preceding the
component declaration, if the *leading* style is used). In this case, the
tag *@enum* is not required::

  --  Colors supported by this drawing application
  type Colors is (
    Black,
    -- The black color is the default color of the pen
    White,
    -- The white color is the default color of the background
    Green);
    -- The green color is the default color of the border

As shown above, a combined approach of documentation is also supported (see
that the general description of the enumeration type *Colors* is located
before its declaration, and the documentation of its literals is located
after their declaration).


Documenting record types
------------------------

The documentation attached to each record type is the block of comment directly
preceeding or directly following the record type declaration and has same
indentation as the record type declaration (to distinguish it from the
multiline in line documentation of the subprograms' parameter or subprogram's
return value).

The following tags are supported when annotating subprograms:

*@field*

   document a record component, with the following syntax:

      *@field <component_name> <description>*

   where:

      *<component_name>*

        is the name of the component as it appears in the subprogram.

      *<description>*

        the documentation for the component; all following text
        is considered for inclusion, until an another tag is encountered.

For example::

  --  A point representing a location in integer precision.
  --  @field X Horizontal coordinate
  --  @field Y Vertical coordinate
  type Point is
   record
      X : Integer;
      Y : Integer;
   end record;

Record components can also be documented inline, with the documentation for
each component directly following its declaration (or directly preceding the
component declaration, if the *leading* style of the documentation is specified).
In this case, the *@field* tag is not required::

  --  A point representing a location in integer precision.
  type Point is
   record
      X : Integer;
      --  Horizontal coordinate
      Y : Integer;
      --  Vertical coordinate
   end record;

As shown above, a combined approach of documentation is also supported (see
that the general description of the record type *Point* is located before
its declaration and the documentation of its components *X* and *Y* is
located after their declaration).


Documenting subprograms
-----------------------

The documentation attached to each subprogram is the block of comment
directly following the subprogram declaration, or directly preceding it
if the *leading* style was specified.

The following tags are supported when annotating subprograms:

*@param*

   document a subprogram parameter, with the following syntax:

      *@param <param_name> <description>*

   where:

      *<param_name>*

        is the name of the parameter as it appears in the subprogram.

      *<description>*

        the documentation for the parameter; all following text is considered
        for inclusion, until an another tag or end of the comment block is
        encountered.

*@return*

   document the return type of a function, with the following syntax:

      *@return <description>*

   where:

      *<description>*

        is the documentation for the return value; all following text is
        considered for inclusion, until an another tag or end of the comment
        block is encountered.

*@exception*

   document an exception, with the following syntax:

      *@exception <exception_name> <description>*

   where:

      *<exception>*

        is the name of the exception potentially raised by the subprogram

      *<description>*

        is the documentation for this exception; all following text is
        considered for inclusion, until an another tag or end of the comment
        block is encountered.


For example::

   function Set_Alarm
     (Message : String;
      Minutes : Natural) return Boolean;
   --  Display a message after the given time.
   --  @param Message The text to display
   --  @param Minutes The number of minutes to wait
   --  @exception System.Assertions.Assert_Failure raised
   --     if Minutes = 0 or Minutes > 300
   --  @return True iff the alarm was successfully registered

The parameters can also be documented inline, with the documentation for each
parameter directly following the parameter type declaration (or directly
preceding the parameter declaration, if the *leading* style of the documentation was
specified). In this case, the *@param* tag is not required::

   function Set_Alarm
     (Message : String;
      --  The text to display
      Minutes : Natural)
      --  The number of minutes to wait
      return Boolean;
      --  Returns True iff the alarm was successfully registered
   --  Display a message after the given time.
   --  @exception System.Assertions.Assert_Failure raised
   --     if Minutes = 0 or Minutes > 300


Text markup
-----------

GNATdoc recognizes several markup constructs inside the description text, which can
be used to better control the format of the generated documentation. GNATdoc's
markup syntax is based on the MarkDown syntax (see `Common Mark <https://commonmark.org/>`_ for a detailed description).

GNATdoc supports the following MarkDown features:

  * paragraphs

  * lists and list items

  * indented code blocks (code blocks are indented by three or more spaces)


Excluding entities
------------------

The *@private* tag indicates that no documentation should be generated
on a given entity. For example::

   type Calculator is tagged ...
   procedure Add (Obj : Calculator; Value : Natural);
   --  Addition of a value to the previus result
   --  @param Obj The actual calculator
   --  @param Value The added value
   procedure Dump_State (Obj : Calculator);
   --  @private No information is generated in the output about this
   --  primitive because it is internally used for debugging.

Note: specifing the *@private* tag for the packages removes the package and all its
child packages from the generated documentation.
