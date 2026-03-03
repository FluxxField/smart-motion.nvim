# Filetype-Aware Pipeline Dispatch Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a patterns collector for vim regex matching and a filetype dispatch middleware that swaps pipeline modules per filetype.

**Architecture:** Two independent modules — a `patterns` collector that yields targets from vim regex matches against buffer lines, and a `filetype_dispatch` middleware in setup.run() that deep-merges per-filetype overrides into the motion definition before module loading. Both are usable independently.

**Tech Stack:** Lua, Neovim API (`vim.fn.matchstrpos`, `vim.bo[].filetype`, `vim.tbl_deep_extend`), smart-motion pipeline/registry system.

---

### Task 1: Patterns Collector

**Files:**
- Create: `lua/smart-motion/collectors/patterns.lua`
- Modify: `lua/smart-motion/collectors/init.lua:1-21`

**Step 1: Create the patterns collector**

Create `lua/smart-motion/collectors/patterns.lua`:

```lua
local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects targets by matching vim regex patterns against buffer lines.
--- @return thread A coroutine generator yielding pattern match targets
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		exit.throw_if(not vim.api.nvim_buf_is_valid(ctx.bufnr), EXIT_TYPE.EARLY_EXIT)

		local patterns = motion_state.patterns
		exit.throw_if(not patterns or #patterns == 0, EXIT_TYPE.EARLY_EXIT)

		local total_lines = vim.api.nvim_buf_line_count(ctx.bufnr)
		local window_size = motion_state.max_lines or 100
		local cursor_line = ctx.cursor_line

		local start_line = math.max(0, cursor_line - window_size)
		local end_line = math.min(total_lines - 1, cursor_line + window_size)

		for line_number = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(ctx.bufnr, line_number, line_number + 1, false)[1]

			if line and #line > 0 then
				for pattern_index, pattern in ipairs(patterns) do
					local search_start = 0

					while search_start < #line do
						local ok, match, match_start, match_end = pcall(vim.fn.matchstrpos, line, pattern, search_start)

						if not ok or match == "" or match_start == -1 then
							break
						end

						if motion_state.patterns_whole_line then
							coroutine.yield({
								text = line,
								line_number = line_number,
								start_pos = { row = line_number, col = 0 },
								end_pos = { row = line_number, col = #line },
								type = "pattern",
								metadata = {
									pattern_index = pattern_index,
								},
							})
							break
						else
							coroutine.yield({
								text = match,
								line_number = line_number,
								start_pos = { row = line_number, col = match_start },
								end_pos = { row = line_number, col = match_end },
								type = "pattern",
								metadata = {
									pattern_index = pattern_index,
								},
							})
						end

						search_start = match_end
					end
				end
			end
		end
	end)
end

M.metadata = {
	label = "Pattern Collector",
	description = "Collects targets by matching vim regex patterns against buffer lines",
}

return M
```

**Step 2: Register the patterns collector**

In `lua/smart-motion/collectors/init.lua`, add the import and registration:

Add after the marks require (line 7):
```lua
local patterns = require("smart-motion.collectors.patterns")
```

Add to `register_many` table (after `marks = marks`):
```lua
	patterns = patterns,
```

**Step 3: Verify the collector loads without errors**

Open Neovim and run:
```
:lua print(vim.inspect(require("smart-motion.collectors").get_by_name("patterns").metadata))
```

Expected: `{ description = "Collects targets by matching vim regex patterns against buffer lines", label = "Pattern Collector" }`

**Step 4: Commit**

```bash
git add lua/smart-motion/collectors/patterns.lua lua/smart-motion/collectors/init.lua
git commit -m "feat: add patterns collector for vim regex matching"
```

---

### Task 2: Filetype Dispatch Middleware

**Files:**
- Create: `lua/smart-motion/core/engine/filetype_dispatch.lua`
- Modify: `lua/smart-motion/core/engine/setup.lua:12-42`

**Step 1: Create the filetype dispatch module**

Create `lua/smart-motion/core/engine/filetype_dispatch.lua`:

```lua
local log = require("smart-motion.core.log")

local M = {}

--- Applies filetype-specific overrides to the motion definition.
--- Modifies motion_state.motion in place (the shallow copy, not the registry).
---@param ctx SmartMotionContext
---@param motion_state SmartMotionMotionState
function M.apply(ctx, motion_state)
	local motion = motion_state.motion
	if not motion or not motion.metadata then
		return
	end

	local ms = motion.metadata.motion_state
	if not ms or not ms.filetype_overrides then
		return
	end

	local filetype = vim.bo[ctx.bufnr].filetype
	if not filetype or filetype == "" then
		return
	end

	local override = ms.filetype_overrides[filetype]
	if not override then
		return
	end

	log.debug(string.format("filetype_dispatch: applying override for filetype '%s'", filetype))

	-- Swap pipeline module references
	for _, key in ipairs({ "collector", "extractor", "modifier", "filter", "visualizer", "action" }) do
		if override[key] then
			motion[key] = override[key]
		end
	end

	-- Deep-merge motion_state overrides into motion.metadata.motion_state
	if override.motion_state then
		motion.metadata.motion_state = vim.tbl_deep_extend("force", ms, override.motion_state)
	end
end

return M
```

**Step 2: Integrate into setup.run()**

In `lua/smart-motion/core/engine/setup.lua`:

Add require at top (after line 6):
```lua
local filetype_dispatch = require("smart-motion.core.engine.filetype_dispatch")
```

Add the middleware call after the shallow copy (after line 20, before line 22):
```lua
	filetype_dispatch.apply(ctx, motion_state)
```

The result should read:
```lua
	-- Shallow copy so infer mutations don't leak to the registry entry
	motion_state.motion = vim.tbl_extend("force", {}, motion)

	filetype_dispatch.apply(ctx, motion_state)

	-- Set motion_key to the trigger key for direct motions.
```

**Step 3: Verify the middleware loads without errors**

Open Neovim in a Lua file and run any existing motion (e.g., press `w`). It should work identically — the middleware early-returns when no overrides are configured.

**Step 4: Commit**

```bash
git add lua/smart-motion/core/engine/filetype_dispatch.lua lua/smart-motion/core/engine/setup.lua
git commit -m "feat: add filetype dispatch middleware to setup pipeline"
```

---

### Task 3: Test Playground

**Files:**
- Create: `tests/patterns.lua`

**Step 1: Create the test playground file**

Create `tests/patterns.lua`:

```lua
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
```

**Step 2: Verify tests work**

1. Add the test motions from the SETUP comment to your config
2. Open `tests/patterns.lua` in Neovim
3. Press `<leader>tp` — labels should appear on snake_case identifiers
4. Press `<leader>tf` — should use patterns (filetype override active for lua)
5. Open a different filetype file, press `<leader>tf` — should use treesitter

**Step 3: Commit**

```bash
git add tests/patterns.lua
git commit -m "test: add patterns collector and filetype dispatch playground"
```
