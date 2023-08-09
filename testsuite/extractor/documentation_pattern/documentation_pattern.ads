
--  This test check extraction of the documentation when documentation pattern
--  is specified. Only comment lines that starts from the '|' are included into
--  the documentation. So, this paragraph is ignored.
--
--|  This is description of the package.

package Documentation_Pattern is

  --|  This is description of the subprogram.
  --
  --  Like other comment lines that doesn't match documentation pattern this
  --  line is not included into the documentation.
  procedure P;

end Documentation_Pattern;
