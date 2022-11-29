
all:
	gprbuild -j0 -p -P gnat/libgnatdoc.gpr -XSUPERPROJECT=
	gprbuild -j0 -p -P gnat/gnatdoc.gpr -XGPR_UNIT_PROVIDER_LIBRARY_TYPE=static -XSUPERPROJECT= -XGPR_UNIT_PROVIDER_BUILD=debug

clean:
	rm -rf .objs bin

build_tests:
	gprbuild -j0 -p -P gnat/tests/test_drivers.gpr

check: build_tests check_extractor

check_extractor:
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json overriding_indicator.ads | diff -u --strip-trailing-cr overriding_indicator.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor pattern.json documentation_pattern.ads | diff -u --strip-trailing-cr documentation_pattern.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json exceptions.ads | diff -u --strip-trailing-cr exceptions.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json records.ads | diff -u --strip-trailing-cr records.out -)
