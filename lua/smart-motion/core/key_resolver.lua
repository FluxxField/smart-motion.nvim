local log = require("smart-motion.core.log")

local M = {}

--- Resolution result types
M.RESOLVE_TYPE = {
	TEXTOBJECT = "textobject",
	COMPOSABLE = "composable",
	FALLBACK = "fallback",
}

--- Non-blocking getchar with timeout. Returns the char or nil on timeout.
--- @param timeout_ms number
--- @return string|nil
local function getchar_with_timeout(timeout_ms)
	local result = nil
	vim.wait(timeout_ms, function()
		local c = vim.fn.getchar(1) -- non-blocking peek
		if c ~= 0 then
			result = type(c) == "number" and vim.fn.nr2char(c) or c
			return true
		end
		return false
	end, 10) -- poll every 10ms
	return result
end

--- Read a single blocking char from user input.
--- @return string|nil char, boolean ok
local function read_char()
	local ok, raw = pcall(vim.fn.getchar)
	if not ok then
		return nil, false
	end
	local char = type(raw) == "number" and vim.fn.nr2char(raw) or raw
	return char, true
end

--- Try to resolve the first char as a textobject prefix (i/a).
--- Reads the next char (blocking) and checks the textobject registry.
--- @param prefix_char string "i" or "a"
--- @param motions_reg table
--- @return table|nil Resolve result, or nil if not a registered textobject
local function try_textobject_prefix(prefix_char, motions_reg)
	local target_char, ok = read_char()
	if not ok or not target_char then
		return nil
	end
	if target_char == "\027" then
		return nil
	end -- ESC

	local textobject = motions_reg.get_textobject(target_char)
	if textobject then
		return {
			type = M.RESOLVE_TYPE.TEXTOBJECT,
			motion_key = target_char,
			textobject_key = prefix_char == "i" and "inside" or "around",
			textobject = textobject,
		}
	end

	-- Not a registered textobject — return as fallback so infer can feed
	-- the full sequence (e.g. "iG") back to vim for native handling.
	return {
		type = M.RESOLVE_TYPE.FALLBACK,
		motion_key = prefix_char .. target_char,
		target_char = target_char,
	}
end

--- Try to resolve the first char as a textobject target directly.
--- Used when the operator pre-sets textobject_key (e.g., ds/cs set "surround").
--- @param char string
--- @param textobject_key string
--- @param motions_reg table
--- @return table|nil Resolve result, or nil if not a registered textobject
local function try_direct_textobject(char, textobject_key, motions_reg)
	local textobject = motions_reg.get_textobject(char)
	if textobject then
		return {
			type = M.RESOLVE_TYPE.TEXTOBJECT,
			motion_key = char,
			textobject_key = textobject_key,
			textobject = textobject,
		}
	end
	return nil
end

--- Resolve a composable motion using multi-char resolution with timeoutlen.
--- @param first_char string
--- @param motions_reg table
--- @return table Resolve result (composable or fallback)
local function resolve_composable(first_char, motions_reg)
	local motion_key = first_char
	local target_motion = motions_reg.get_composable_by_key(motion_key)

	while motions_reg.has_composable_with_prefix(motion_key) do
		local next_char = getchar_with_timeout(vim.o.timeoutlen)
		if not next_char then
			break
		end -- timeout, use current match
		if next_char == "\027" then
			break
		end -- ESC, use current match

		local longer_key = motion_key .. next_char
		local longer_match = motions_reg.get_composable_by_key(longer_key)

		if longer_match or motions_reg.has_composable_with_prefix(longer_key) then
			motion_key = longer_key
			target_motion = longer_match or target_motion
		else
			-- Extra char doesn't extend any composable — push it back
			vim.api.nvim_feedkeys(next_char, "t", false)
			break
		end
	end

	if target_motion then
		return {
			type = M.RESOLVE_TYPE.COMPOSABLE,
			motion_key = motion_key,
			composable = target_motion,
		}
	end

	return {
		type = M.RESOLVE_TYPE.FALLBACK,
		motion_key = motion_key,
	}
end

--- Resolve the key sequence after an operator in infer context.
---
--- Resolution priority:
---   1. If motion_state.textobject_key is pre-set (ds/cs operators), look up
---      first char directly in textobject registry.
---   2. If first char is "i" or "a", read next char and look up in textobject
---      registry. If not found, return fallback for native vim handling.
---   3. Otherwise, resolve as composable motion using multi-char resolution
---      with timeoutlen.
---
--- @param motion_state SmartMotionMotionState
--- @return table|nil result with fields: type, motion_key, textobject_key?, textobject?, composable?
function M.resolve(motion_state)
	local motions_reg = require("smart-motion.motions")

	local first_char, ok = read_char()
	if not ok or not first_char then
		return nil
	end
	if first_char == "\027" then
		return nil
	end -- ESC cancels

	-- Priority 1: Operator pre-set textobject_key (ds/cs operators)
	if motion_state.textobject_key then
		local result = try_direct_textobject(first_char, motion_state.textobject_key, motions_reg)
		if result then
			return result
		end
		-- Not a textobject — fall through to composable/fallback
	end

	-- Priority 2: i/a textobject prefix (only if operator hasn't pre-set textobject_key)
	if not motion_state.textobject_key and (first_char == "i" or first_char == "a") then
		local result = try_textobject_prefix(first_char, motions_reg)
		if not result then
			return nil -- ESC/error
		end

		if result.type == M.RESOLVE_TYPE.TEXTOBJECT then
			return result
		end

		-- Not a textobject. For standard operators (d/y/c), fall back to native vim.
		-- For operators that opt in (e.g. ys), try composable resolution instead.
		if motion_state.ia_resolve_composable and result.target_char then
			local composable_result = resolve_composable(result.target_char, motions_reg)
			composable_result.textobject_key = first_char == "i" and "inside" or "around"
			return composable_result
		end

		return result
	end

	-- Priority 3: Composable motion resolution
	return resolve_composable(first_char, motions_reg)
end

return M
