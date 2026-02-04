-- SmartMotion Playground: Diagnostic Motions
-- Presets: ]d, [d, ]e, [e
--
-- INSTRUCTIONS:
--   ]d → jump to next diagnostic (any severity)
--   [d → jump to previous diagnostic
--   ]e → jump to next ERROR diagnostic only
--   [e → jump to previous ERROR diagnostic only
--
-- REQUIREMENTS:
--   This file needs an LSP server (lua_ls) to generate real diagnostics.
--   Ensure lua_ls is configured and attached to this buffer.
--   Check with :LspInfo
--
-- MULTI-WINDOW:
--   :vsplit tests/treesitter.lua
--   Press ]d — labels should appear on diagnostics in BOTH windows

-- ── Section 1: Undefined variable errors ──────────────────────

-- These produce "Undefined global" diagnostics with lua_ls

local result1 = undefined_variable_alpha + 10
local result2 = undefined_variable_beta * 2
local result3 = undefined_variable_gamma .. " text"

-- ── Section 2: Type mismatch warnings ─────────────────────────

---@param count integer
---@param name string
---@return string
local function format_entry(count, name)
  return name .. ": " .. count -- type warning: count is integer, concat expects string
end

---@param items string[]
---@return integer
local function sum_items(items)
  local total = 0
  for _, item in ipairs(items) do
    total = total + item -- type warning: item is string, arithmetic expects number
  end
  return total
end

-- ── Section 3: Unused variable warnings ───────────────────────

local unused_alpha = "this is never used"
local unused_beta = 42
local unused_gamma = { 1, 2, 3 }
local unused_delta = true

local function unused_params(important, also_important, ignored_param)
  return important + also_important
end

-- ── Section 4: Deprecated function warnings ───────────────────

---@deprecated Use new_api() instead
local function old_api(data)
  return data
end

local value = old_api("test") -- should show deprecated warning

---@deprecated
local function legacy_handler(event)
  return event
end

local handled = legacy_handler("click") -- deprecated warning

-- ── Section 5: Mixed severity diagnostics ─────────────────────

-- This section has both errors and warnings mixed together
-- Try ]e to jump to only errors, ]d to jump to all diagnostics

local error_one = completely_undefined_function() -- ERROR: undefined
local warn_one = old_api("warn") -- WARNING: deprecated

local fine = "this line is fine"

local error_two = another_missing_global -- ERROR: undefined
local warn_two = legacy_handler("warn") -- WARNING: deprecated

local also_fine = tostring(42)

local error_three = yet_another_undefined() -- ERROR: undefined

-- ── Section 6: Valid code (no diagnostics) ────────────────────

-- This section is clean — diagnostics from above should NOT appear here
-- Use this as a starting point: press ]d to jump to the first diagnostic

local function clean_function(x, y)
  return x + y
end

local function another_clean_function(items)
  local result = {}
  for i, v in ipairs(items) do
    result[i] = tostring(v)
  end
  return result
end

local data = { 1, 2, 3, 4, 5 }
local strings = another_clean_function(data)
local total = clean_function(10, 20)
print(table.concat(strings, ", "))
print("Total: " .. tostring(total))

-- ── Verification ──────────────────────────────────────────────
-- 1. Place cursor in Section 6 (clean code)
-- 2. Press ]d — should jump to first diagnostic above
-- 3. Press ]d again — next diagnostic
-- 4. Press [d — previous diagnostic
-- 5. Press ]e — should skip warnings, jump to errors only
-- 6. Press [e — previous error only
