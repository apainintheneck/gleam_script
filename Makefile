export XDG_CACHE_HOME = .gscript_test

script = $(XDG_CACHE_HOME)/test.gleam
escript = $(XDG_CACHE_HOME)/test
internal_dir = $(XDG_CACHE_HOME)/gleam_script

default: lint clean test

lint:
	@echo \# Run linter
	gleam format --check src
	@echo

test:
	@echo \# Prep: Create test directory
	mkdir -p $(XDG_CACHE_HOME)
	@echo

	@echo \# 1. gleam_script new FILE
	test ! -f $(script)
	gleam run -- new $(script) --verbose
	test -f $(script)
	@echo

	@echo \# 2. gleam_script run FILE
	test ! -d $(internal_dir)
	gleam run -- run $(script) --verbose
	test -d $(internal_dir)
	@echo

	@echo \# 3. gleam_script export FILE
	test ! -f $(escript)
	gleam run -- export $(script) --verbose
	test -f $(escript)
	./$(escript)
	@echo

	@echo \# 4. gleam_script check FILE
	gleam run -- check $(script) --verbose
	@echo

	@echo \# 5. gleam_script deps FILE
	gleam run -- deps $(script) --verbose
	@echo

	@echo \# 6. gleam_script clean
	test -d $(internal_dir)
	gleam run -- clean --verbose
	test ! -e $(internal_dir)
	@echo

	@echo \# 7. gleam_script help
	gleam run -- help --verbose
	@echo

release: default
	@echo \# Creating escript
	gleam build
	gleam run -m gleescript
	@echo

clean:
	@echo \# Clean up local test directory
	test ! -e $(XDG_CACHE_HOME) || rm -Ir $(XDG_CACHE_HOME)
	@echo
