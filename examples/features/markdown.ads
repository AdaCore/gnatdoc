
--  GNATdoc understands a markup language based on
--  [CommonMark](https://commonmark.org/), which can be used to format
--  elements in the generated documentation.
--
--  The following features are supported:
--   * paragraphs
--   * ordered and unordered lists
--   * indented code blocks
--   * inline formatting, including **strong emphasis** (**bold text**),
--     *emphasis* (*italicized text*), and `code spans` (`monospace text`)
--   * images
--
--  To have a block recognized as code, indent it with at least three spaces:
--
--     with Ada.Text_IO;
--
--     procedure Hello_World is
--     begin
--        Ada.Text_IO.Put_Line ("Hello, worlds!");
--     end Hello_World;
--
--  Some backends require the size of images to be specified. When an image is
--  declared without a size, the image might be invisible or shown with the
--  wrong size, like this one ![Ada Inside](ada_logo_32x32.png). GNATdoc
--  supports the following syntax to provide an image size. This guarantees
--  this image will be represented properly on all backends
--  ![Ada Inside](ada_logo_64x64.png){width=14pt height=14pt}.

package Markdown is

end Markdown;
