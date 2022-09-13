
all:
	gprbuild -j0 -p -P gnat/libgnatdoc.gpr -XSUPERPROJECT=
	gprbuild -j0 -p -P gnat/gnatdoc.gpr -XGPR_UNIT_PROVIDER_LIBRARY_TYPE=static -XSUPERPROJECT= -XGPR_UNIT_PROVIDER_BUILD=debug

clean:
	rm -rf .objs bin

build_tests:
	gprbuild -j0 -p -P gnat/tests/test_drivers.gpr

check: build_tests check_extractor

check_extractor:
	(cd testsuite/extractor && ../../.objs/test_extractor gnat overriding_indicator.ads | diff -u overriding_indicator.out -)
