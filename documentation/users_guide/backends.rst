********
Backends
********


HTML
====

The HTML backend is default backend of the GNATdoc.

Command line options
--------------------

The HTML backend can generate documentation structure in two formats.

  * Group all entities by compilation units (the default)

  * Group tagged types, its dispatching subprograms and subprograms that can be
    used by prefixed notation separately, and group other entities by
    compilation units. This format can be renabled by adding the *:oop* qualifier
    at the end of the *--backend* command line switch, as in:

    gnatdoc --backend=html:oop -P project.gpr


Layout of the resources directory
---------------------------------

  *<resources_dir>/static*
    The content of this directory is copied into the directory of the generated
    documentation. This can be used to provide additional files like CSS,
    images, etc.

  *<resources_dir>/templates*
    Directory of the XHTML templates that are used to generate documentation. It
    contains the files described below.

  *<resources_dir>/templates/index.xhtml*
    The template for the home page of the generated documentation.

  *<resources_dir>/templates/unit.xhtml*
    The template for the documentation of the compilation unit.

  *<resources_dir>/templates/class.xhtml*
    The template for the documentation of the class (when generation of the OOP
    style documentation is specified)


ODF
===

The ODF backend can be used to generate documentation in OpenDocument Format
(ODF) format. The generated file can be opened by many office suites
(Microsoft Word, LibreOffice Writer, etc) to apply different styles and print
the documentation.

Output can be customized by providing a custom
*<resources_dir>/template/documentation.fodt* file.


RST
===

The RST backend can be used to generate a set of *.rst* files to be used to generate
documentation with *sphinx* configured with *ada-domain*.


XML
===

The XML backend can be used to export documentation in XML format to process it
by other tools.
