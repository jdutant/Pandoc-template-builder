
all: help

.PHONY: help
help:
	@echo Use `test` to test the script and `generate` to
	@echo regenerate the test file.

.PHONY: test
test: template-builder.lua
	@pandoc lua $< -i test/expected.latex \
	| diff test/expected.latex -

.PHONY: generate
generate: template-builder.lua
	@pandoc lua $< -i test/src.latex -o test/expected.latex