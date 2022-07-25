# Command Line

GNATdoc supports following switches:

 -P project.gpr

   Specify project file to process.

 -X NAME=VALUE

   Specify scenario variable to use in project files.

 --generate=[public,private,body]

   Select subset of entities to generate documentation:

   public - only entities declared in public part of the packages

   private - generate documentation for entities declared in package
     specifications (public and private parts)

   body - generate documentation for entities in both specifications and
     bodies

 --style=[leading,trailing,gnat]

   leading - documentation is extracted from the leading comments

   trailing - documentation is extracted from the trailing comments

   gnat - documentation is extracted from the trailing comments and additional
     features of the GNAT style are enabled
