PREFIX ?= `pwd`/install
docdir = ${PREFIX}/share/doc/gnatdoc

SCENARIO_VARIABLES=\
	-XGPR_UNIT_PROVIDER_LIBRARY_TYPE=static \
	-XGPR_UNIT_PROVIDER_BUILD=debug \
	-XVSS_LIBRARY_TYPE=static \
	-XMARKDOWN_LIBRARY_TYPE=static \
	-XLIBADALANG_LIBRARY_TYPE=static \
	-XLANGKIT_SUPPORT_LIBRARY_TYPE=static \
	-XPRETTIER_ADA_LIBRARY_TYPE=static \
	-XGPR2_LIBRARY_TYPE=static

all: build-gnatdoc

build-all: build-libgnatdoc build-gnatdoc build-tests

install: install-gnatdoc

build-libgnatdoc:
	gprbuild -j0 -p -P gnat/libgnatdoc.gpr

build-gnatdoc:
	gprbuild -j0 -p -P gnat/gnatdoc.gpr ${SCENARIO_VARIABLES}

install-gnatdoc:
	gprinstall -f -p -P gnat/gnatdoc.gpr --prefix="${PREFIX}" --no-project ${SCENARIO_VARIABLES}

clean:
	rm -rf .objs bin

build-tests:
	gprbuild -j0 -p -P gnat/tests/test_drivers.gpr ${SCENARIO_VARIABLES}

check: build-tests
	make -C testsuite

build-documentation:
	make -C documentation/users_guide html latexpdf

install-documentation: build-documentation
	mkdir -p $(docdir)/html
	mkdir -p $(docdir)/html/users_guide
	mkdir -p $(docdir)/pdf
	cp -r documentation/users_guide/_build/html/* $(docdir)/html/users_guide
	cp documentation/users_guide/_build/latex/gnatdoc_ug.pdf $(docdir)/pdf

####################
# Coverage support #
####################

coverage-setup: clean
# Create a local gnatcov RTS - do not do this in the gnatcov install prefix
	gnatcov setup --prefix=$$(pwd)/.objs/gnatcov-rts

coverage-instrument: coverage-setup
# Create the instrumented sources for gnatdoc and libgnatdoc.
# Do not process subprojects, to avoid measuring coverage on
# the markdown subproject.
	gnatcov instrument -P gnat/gnatdoc.gpr \
		--level=stmt \
		--projects=gnatdoc.gpr --projects=libgnatdoc.gpr \
	    --runtime-project $$(pwd)/.objs/gnatcov-rts/share/gpr/gnatcov_rts.gpr \
		--no-subprojects \
		${SCENARIO_VARIABLES}

coverage-build: coverage-instrument
# Build the project and the test drivers
	gprbuild -j0 -p -P gnat/gnatdoc.gpr \
	    --src-subdirs=gnatcov-instr \
	    --implicit-with=$$(pwd)/.objs/gnatcov-rts/share/gpr/gnatcov_rts.gpr \
		${SCENARIO_VARIABLES}
	gprbuild -j0 -p -P gnat/tests/test_drivers.gpr \
	    --implicit-with=$$(pwd)/.objs/gnatcov-rts/share/gpr/gnatcov_rts.gpr \
		${SCENARIO_VARIABLES}

coverage-test: coverage-build
# Run the testsuite with the instrumented binaries; aggregate the
# traces in a local directory.
	rm -rf gnatcov_traces
	mkdir -p gnatcov_traces
	export PATH=$$(pwd)/bin:$$PATH && \
	export GNATCOV_TRACE_FILE=$$(pwd)/gnatcov_traces/ && \
	make -C testsuite

coverage-report: coverage-test
# Create a report from the traces; use the HTML and Cobertura formats for
# the report, and place it in a local directory.
	export GNATCOV_TRACE_FILE=$$(pwd)/gnatcov_traces/ && \
	gnatcov coverage -P gnat/gnatdoc.gpr \
	    --level=stmt \
		--annotate=html,cobertura \
		--projects=gnatdoc.gpr --projects=libgnatdoc.gpr \
		--output-dir gnatcov_report/ \
		gnatcov_traces/
