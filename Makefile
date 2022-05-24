
all:
	gprbuild -j0 -p -P gnat/libgnatdoc.gpr
	gprbuild -j0 -p -P gnat/gnatdoc.gpr

clean:
	rm -rf .objs bin
