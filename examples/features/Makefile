
GNATDOC=gnatdoc
#GNATDOC_FLAGS=--style=leading
GNATDOC_FLAGS=--style=gnat

all: clean
	$(GNATDOC) $(GNATDOC_FLAGS) default.gpr
	$(GNATDOC) $(GNATDOC_FLAGS) default.gpr --backend=odf
	$(GNATDOC) $(GNATDOC_FLAGS) default.gpr --backend=rst

clean:
	rm -rf docs html odf
