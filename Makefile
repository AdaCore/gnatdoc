
all:
	gprbuild -j0 -p -P gnat/libgnatdoc.gpr
	gprbuild -j0 -p -P gnat/gnatdoc.gpr -XGPR_UNIT_PROVIDER_LIBRARY_TYPE=static -XGPR_UNIT_PROVIDER_BUILD=debug -XVSS_LIBRARY_TYPE=static -XMARKDOWN_LIBRARY_TYPE=static

clean:
	rm -rf .objs bin

build_tests:
	gprbuild -j0 -p -P gnat/tests/test_drivers.gpr

check: build_tests check_extractor check_gnatdoc

check_extractor:
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json overriding_indicator.ads | diff -u --strip-trailing-cr overriding_indicator.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor pattern.json documentation_pattern.ads | diff -u --strip-trailing-cr documentation_pattern.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json exceptions.ads | diff -u --strip-trailing-cr exceptions.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json records.ads | diff -u --strip-trailing-cr records.ads.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json tasks.ads | diff -u --strip-trailing-cr tasks.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json protecteds.ads | diff -u --strip-trailing-cr protecteds.ads.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json protecteds.adb | diff -u --strip-trailing-cr protecteds.adb.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json subprograms_gnat.ads | diff -u --strip-trailing-cr subprograms_gnat.ads.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json test_vb10_011.ads | diff -u --strip-trailing-cr test_vb10_011.ads.out -)
	(cd testsuite/extractor && ../../.objs/test_extractor gnat.json enumerations.ads | diff -u --strip-trailing-cr enumerations.ads.out -)

check_gnatdoc:
	make -C testsuite/gnatdoc.RB16-013.gpt_tool
