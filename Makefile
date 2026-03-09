NVIM ?= nvim

.PHONY: test test-file

test:
	$(NVIM) --headless -u tests/run_tests.lua

test-file:
	$(NVIM) --headless -u tests/run_tests.lua -- $(FILE)
