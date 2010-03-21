MODULES="netclient json-wheel str shell"

all: github_clone

github_clone: github_clone.ml
	ocamlfind opt -package $(MODULES) -linkpkg github_clone.ml -o github_clone

clean:
	rm gihub_clone.cm[xi] github_clone.o github_clone