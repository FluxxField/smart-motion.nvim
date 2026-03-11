-- Test runner entry point
-- Usage: nvim --headless -u tests/run_tests.lua
-- Or:    make test

-- Determine project root from this script's location
local this_file = debug.getinfo(1, "S").source:sub(2)
local project_root = vim.fn.fnamemodify(this_file, ":h:h")

-- Add project to runtimepath so require("smart-motion") works
vim.opt.runtimepath:prepend(project_root)

-- Add deps/ to package.path so require("mini_test") works
package.path = project_root .. "/deps/?.lua;" .. package.path

-- Disable swap files and shada for test isolation
vim.o.swapfile = false
vim.o.shadafile = "NONE"

-- Load mini.test
local MiniTest = require("mini_test")

-- Collect test files: all tests/test_*.lua files
local test_dir = project_root .. "/tests"
local test_files = {}

-- Check if a specific file was passed via command line args
local cli_file = nil
for i, arg in ipairs(vim.v.argv) do
	if arg == "--" and vim.v.argv[i + 1] then
		cli_file = vim.v.argv[i + 1]
		break
	end
end

if cli_file then
	table.insert(test_files, test_dir .. "/" .. cli_file)
else
	local files = vim.fn.glob(test_dir .. "/test_*.lua", false, true)
	table.sort(files)
	test_files = files
end

-- Run tests with stdout reporter for headless
MiniTest.setup({
	collect = {
		find_files = function()
			return test_files
		end,
	},
	script_path = this_file,
})

MiniTest.run()
