-- SmartMotion Playground: Patterns Collector & Filetype Dispatch
-- Tests: patterns collector standalone, filetype_overrides
--
-- SETUP:
--   Add these motions to your smart-motion config for testing:
--
--   After sm.setup(opts), register test motions:
--
--   sm.motions.register("test_patterns", {
--     collector = "patterns",
--     extractor = "pass_through",
--     filter = "filter_visible",
--     visualizer = "hint_start",
--     action = "jump",
--     map = true,
--     trigger_key = "<leader>tp",
--     modes = { "n" },
--     metadata = {
--       label = "Test Patterns",
--       motion_state = {
--         patterns = { "\\v\\w+_\\w+" },
--       },
--     },
--   })
--
--   sm.motions.register("test_ft_dispatch", {
--     collector = "treesitter",
--     extractor = "pass_through",
--     filter = "filter_visible",
--     visualizer = "hint_start",
--     action = "jump",
--     map = true,
--     trigger_key = "<leader>tf",
--     modes = { "n" },
--     metadata = {
--       label = "Test FT Dispatch",
--       motion_state = {
--         ts_node_types = { "function_declaration", "function_definition" },
--         filetype_overrides = {
--           lua = {
--             collector = "patterns",
--             motion_state = {
--               patterns = { "\\vlocal%s+\\zs\\w+" },
--             },
--           },
--         },
--       },
--     },
--   })

-- ── Section 1: Patterns Collector (standalone) ─────────────────

-- TEST: <leader>tp should show labels on snake_case identifiers
-- The pattern \v\w+_\w+ matches words with underscores

local my_variable = "hello"
local another_var = "world"
local snake_case_name = "test"
local camelCase = "no match"
local with_multiple_underscores = "matches"
local x = "no match"

local function some_function_name()
	local inner_var = "match"
	return inner_var
end

-- ── Section 2: Multiple matches per line ────────────────────────

-- TEST: <leader>tp should find multiple matches on a single line

local first_match, second_match, third_match = 1, 2, 3
-- All three snake_case names above should get labels

-- ── Section 3: Filetype dispatch ────────────────────────────────

-- TEST: <leader>tf in this Lua file should use patterns collector
-- (matching "local" variable names) instead of treesitter.
-- The filetype_overrides config swaps collector to "patterns"
-- when filetype == "lua".
--
-- Open a .js or .py file — <leader>tf should use treesitter there
-- (since no override exists for those filetypes).

local alpha = 1
local bravo = 2
local charlie = 3

-- ── Section 4: Operator composition ─────────────────────────────

-- TEST: Operators should compose with pattern-based motions.
-- If you have d mapped with infer, try:
--   d<leader>tp → delete-jump to a pattern match
--   y<leader>tp → yank-jump to a pattern match
--
-- The filetype dispatch runs before infer, so the override
-- is already applied when the operator composes.

local delete_this_target = "try deleting me"
local yank_this_target = "try yanking me"

-- ── Section 5: Whole-line mode ──────────────────────────────────

-- To test patterns_whole_line, register a motion with:
--   motion_state = {
--     patterns = { "TODO" },
--     patterns_whole_line = true,
--   }
-- Each TODO line becomes a full-line target:

-- TODO: first task
-- TODO: second task
-- FIXME: not a match
-- TODO: third task
