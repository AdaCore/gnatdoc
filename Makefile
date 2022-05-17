
all:
	gprbuild -P gnat/libgnatdoc.gpr
	gprbuild -P gnat/gnatdoc.gpr

clean:
	rm -rf .objs bin
