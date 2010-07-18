
PROGNAME=github_clone
FILES=github_clone.ml
MODULES="netclient json-wheel str shell"


all: opt

opt: $(FILES)
	ocamlfind opt -package $(MODULES) -linkpkg $(FILES) -o $(PROGNAME)

byte: $(FILES)
	ocamlfind c -package $(MODULES) -linkpkg $(FILES) -o $(PROGNAME)


FILENAMES := $(patsubst %.mli,%,$(FILES))
FILENAMES := $(patsubst %.ml,%,$(FILENAMES))

clean:
	$(foreach filename, $(FILENAMES), rm -rf ${filename}{,.cmi,.cmo,.cmx,.o})
