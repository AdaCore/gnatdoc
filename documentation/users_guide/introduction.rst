************
Introduction
************

GNATdoc is a documentation tool for Ada which processes source files, extracts
documentation directly from the sources, and generates annotated HTML files.
It also relies on standard comments that it extracts from the source code. The
engine in charge of extracting them coupled with the cross-reference engine
gives GNATdoc all the flexibility needed to generate accurate documentation,
and report errors in case of wrong documentation.


Installation
------------

GNATdoc is shipped as part of the GNAT Studio package. To install it, simply
launch the GNAT Studio installer.

After the installation place
:file:`<gnatstudio_installation_prefix>/bin/` in your PATH environment
variable.


Launching GNATdoc
-----------------

GNATdoc requires your project hierarchy to be described via GNAT project
files (.gpr).

To launch GNATdoc, execute::

      gnatdoc <your_project>

where :file:`<your_project>` is the .gpr file at the root of your project
hierarchy (your root project).

GNATdoc generates an HTML report in the :file:`gnatdoc` directory of the object
directory of the main project.


Command line interface
----------------------

A brief description of the supported switches is available through the
switch --help::

  $ gnatdoc --help
  Usage: gnatdoc4 [options] project_file

  Options:
    --backend <name>           Backend to use to generate output
    --generate <part>          Part of code to generate documentation
    -O, --output-dir <output_dir>
                               Output directory for generated documentation
    -P, --project <project_file>
                               Project file to process
    --style <style>            Use given style of documentation
    --warnings                 Report warnings for undocumented entities
    -X                         Set scenario variable
    -h, --help                 Display help information

  Arguments:
    project_file               Project file to process


*Output format (--backend=<name>)*

  At current stage GNATdoc generates HTML files (*--backend=html*), or ReST
  files (*--backend=rst*).


*Subset of entities to be included into the documentation (*--generate=<part>)*

  *public* 
    Entities declared in the public part of the package specification. Is it
    default.

  *private*
    Entities declared in the package specification, in both public and private
    parts.

  *body*
    All entities declared in the both package specification and library level
    of the package body.


*Output directory (-O, --output-dir=<path>)*

  Directory to output generated documentation. This option overrides value of
  the Documentation'Output_Dir attribute defined in the project file.


*Project (-P, --project=<file>)*

  Specify the path name of the main project file. The space between -P and
  the project file name is optional.


*Documentation comments style (--style=<style>)*

  *leading*
    Documentation is extracted from the comment before the entity declaration.

  *trailing*
    Documentation is extracted from the comment after the entity declaration.

  *gnat*
    Documentation is extracted from the comment after the entity declaration
    and additional features of the GNAT style are enabled.


*Enable warnings for missing documentation (--warnings)*

  Emit warnings for fields, parameters or subprograms which do not have
  documentation.

*External reference (-X NAME=VALUE)*

  Specify an external reference in the project.


..  GNAT Studio interface
    ---------------------

..  GNATdoc can be invoked from GNAT Studio through the menu
    Analyze-> Documentation-> Generate project to generate the documentation
    for all files from the loaded project.

..  You will find the list of all documentation options in
    the menu Edit-> Preferences-> Documentation.

..  Once the documentation is generated, the main documentation file is
    loaded in your default browser.
