********
Backends
********


HTML
====

HTML backend is default backend of the GNATdoc.


Command line options
--------------------

HTML backend can generate documentation structure in two formats.

  * Group all entities by compilation units (it is default format)

  * Group tagged types, its dispatching subprograms and subprograms that can be
    used by prefixed notation separately, and group other entities by
    compilation units.

Use of second format can be renabled by use of *:oop* qualifier of the
*--backend* command line switch, like:

    gnatdoc --backend=html:oop project.gpr


Layout of the resources directory
---------------------------------

  *<resources_dir>/static*
    Content of this directory is copied into the directory of the generated
    documentation. This can be used to provide additional files like CSS,
    images, etc.

  *<resources_dir>/templates*
    Directory of the XHTML templates to be used to generate documentation. It
    contains files described below.

  *<resources_dir>/templates/index.xhtml*
    Template for the home page of the generated documentation.

  *<resources_dir>/templates/unit.xhtml*
    Template for the documentation of the compilation unit.

  *<resources_dir>/templates/class.xhtml*
    Template for the documentation of the class (then generation of the OOP
    style documentation is sepecified)



RST
===

RST backend is indented to generate set of *.rst* files to be used to generate
documentation with *sphynx* with *ada-domain*.
