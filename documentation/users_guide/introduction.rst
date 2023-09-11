************
Introduction
************

GNATdoc is a documentation tool for Ada which processes source files, extracts
documentation from the sources, and generates either annotated HTML files or
Restructured Text (.rst) files.

It relies on documentation comments that it extracts from the source code. The
engine in charge of extracting these comments, coupled with a cross-reference
engine, gives GNATdoc all the flexibility needed to generate accurate documentation,
and report errors in cases of missing documentation.


Installation
------------

GNATdoc is shipped as part of the GNAT Studio package. To install it,
launch the GNAT Studio installer.

After the installation, place
:file:`<gnatstudio_installation_prefix>/bin/` in your PATH environment
variable.


Launching GNATdoc
-----------------

GNATdoc requires your project hierarchy to be described via GNAT project
files (.gpr).

To launch GNATdoc, execute::

      gnatdoc -P <your_project>

where :file:`<your_project>` is the .gpr file at the root of your project
hierarchy (referred to here as the root project).

GNATdoc generates an HTML report in the :file:`gnatdoc` directory of the object
directory of the root project.


Command line interface
----------------------

A brief description of the supported switches is available through the
`--help` switch::

  $ gnatdoc --help
  Usage: gnatdoc [options] project_file

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

Here is the list of supported switches:

*  `-P, --project=<file>`: specify the project file

   Specify the path name of the main project file. The space between -P and
   the project file name is optional.

* `-X <NAME>=<VALUE>`: Project external references

  Specify an external reference in the project. This can be used multiple times.

* `--backend=<name>`: select the output format

  GNATdoc generates HTML files (*--backend=html*), or ReST
  files (*--backend=rst*). The default is HTML.

* `--generate=<part>`: Select the of entities to be included into the documentation

  *public*
    Entities declared in the public part of the package specification. This is the
    default.

  *private*
    Entities declared in the package specifications, in both public and private
    parts.

  *body*
    All entities declared in the both package specifications and at library level
    in package bodies.

* `-O, --output-dir=<path>`: Output directory

  Directory to output generated documentation. This option overrides the value of
  the Documentation'Output_Dir attribute defined in the project file.

* `--style=<style>`: Documentation comments style

  *leading*
    Documentation is extracted from the comment before the entity declaration.

  *trailing*
    Documentation is extracted from the comment after the entity declaration.

  *gnat*
    Documentation is extracted from the comment after the entity declaration
    and additional features of the GNAT style are enabled.


* `--warnings`: Enable warnings for missing documentation

   Emit warnings for fields, parameters or subprograms which do not have
   documentation.


..  GNAT Studio interface
    ---------------------

..  GNATdoc can be invoked from GNAT Studio through the menu
    Analyze-> Documentation-> Generate project to generate the documentation
    for all files from the loaded project.

..  You will find the list of all documentation options in
    the menu Edit-> Preferences-> Documentation.

..  Once the documentation is generated, the main documentation file is
    loaded in your default browser.
