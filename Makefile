ML = insideout_ast.ml insideout_lexer.ml insideout_emit.ml insideout_main.ml
OCAMLFLAGS = -safe-string -annot

insideout: $(ML)
	ocamlopt $(OCAMLFLAGS) -o $@ str.cmxa $^

insideout_lexer.ml: insideout_lexer.mll
	ocamllex $<

.PHONY: demo
demo: example
	./insideout example.html -preview -o preview.html
	./example > out.html

example: example_styles.ml example.ml example_main.ml
	ocamlopt $(OCAMLFLAGS) -o example $^

example.ml: insideout example.html
	./insideout example.html -o example.ml -esc-html -open Example_styles

ifndef PREFIX
  PREFIX = $(HOME)
endif

ifndef BINDIR
  BINDIR = $(PREFIX)/bin
endif

.PHONY: install
install:
	cp insideout $(BINDIR)

.PHONY: clean
clean:
	rm -f *.o *.cm* *~ insideout_lexer.ml insideout
	rm -f example.ml example preview.html out.html
