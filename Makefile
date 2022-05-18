
all:
	gprbuild -p -P gnat/libgnatdoc.gpr
	gprbuild -p -P gnat/gnatdoc.gpr

clean:
	rm -rf .objs bin
