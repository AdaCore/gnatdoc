
all:
	gprbuild -P gnat/libgnatdoc.gpr

clean:
	rm -rf .objs
