# Backends

## Static HTML

Static HTML backend generated documentation as set of HTML files.

### Resources directories

HTML backend allows to customize output by adding/replacing of static files, as
well as by using modified templates to generate documentation.

Here is expected structure of the resources directory.

 \                  root resource directory of the backend
 | \static          static resource files
 | \templates       XHTML templates files
   | \index.xhtml   template to use to generate index.html file
   | \docs.xhtml    template to use to generate individual documentation files
