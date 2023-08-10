
SCENARIO_VARIABLES=-XGPR_UNIT_PROVIDER_LIBRARY_TYPE=static -XGPR_UNIT_PROVIDER_BUILD=debug -XVSS_LIBRARY_TYPE=static -XMARKDOWN_LIBRARY_TYPE=static

all:
	gprbuild -j0 -p -P gnat/libgnatdoc.gpr
	gprbuild -j0 -p -P gnat/gnatdoc.gpr ${SCENARIO_VARIABLES}

clean:
	rm -rf .objs bin

build_tests:
	gprbuild -j0 -p -P gnat/tests/test_drivers.gpr ${SCENARIO_VARIABLES}

check: build_tests check_extractor check_gnatdoc

check_extractor:
	make -C testsuite

check_gnatdoc:
	make -C testsuite/gnatdoc.RB16-013.gpr_tool
