PREFIX ?= `pwd`/install
docdir = ${PREFIX}/share/doc/gnatdoc

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

build-documentation:
	make -C documentation/users_guide html latexpdf

install-documentation: build-documentation
	mkdir -p $(docdir)/html
	mkdir -p $(docdir)/html/users_guide
	mkdir -p $(docdir)/pdf
	cp -r documentation/users_guide/_build/html/* $(docdir)/html/users_guide
	cp documentation/users_guide/_build/latex/gnatdoc_ug.pdf $(docdir)/pdf
