# Project Files

GNATdoc use some attributes of the package Documentation of the project file.
Supported attributes are listed below. Only attributes specified in the root
project file are used.

## Documentation_Pattern

Regular expression to detect comment lines to be included into the
documentation. Regular expression should include two minus signs (start of the
Ada comment). All text starting from the beginning of the line and including
text that match regular expression are removed from the documentation line.

## Excluded_Project_Files

List of project files to exclude from documentation generation. This list may
include any project files directly or undirectly used by the root project.

Note, externally build library project files are excluded from the
documentation generation unconditionally.

## Image_Dirs

List of directories (relative to directory of the root project file) to lookup
for images referenced in the documentation.

## Output_Dir

Allows to specify output directory for the generated documentation.

When the name of the backend is specified it is path to the directory to output
generated documentation, otherwise generated documentation will be output the
the subdirectory of the specified output directory.

## Resources_Dir

Additional resources directory for backend.

Each supported backend has own convention on use of resource directory, see
documentation for particular backend.

When the name of the backend is specified it is path to the directory to lookup
for backend's resources; otherwise backend's resources are looked in the
subdirectory of the specified directory.
