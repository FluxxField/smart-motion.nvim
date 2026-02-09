local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local module_loader = require("smart-motion.utils.module_loader")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

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

function M.run(ctx, cfg, motion_state)
	if not motion_state.motion.infer then
		return
	end

	local ok, raw_key = exit.safe(pcall(vim.fn.getchar))
	exit.throw_if(not ok, EXIT_TYPE.EARLY_EXIT)

	local first_char = type(raw_key) == "number" and vim.fn.nr2char(raw_key) or raw_key
	exit.throw_if(first_char == "\027", EXIT_TYPE.EARLY_EXIT)

	-- Multi-char resolution: check for longer composable motions after reading first char.
	-- If the current char is both a composable match AND a prefix of longer composable keys,
	-- wait up to timeoutlen for more input.
	local motions_reg = require("smart-motion.motions")
	local motion_key = first_char
	local target_motion = motions_reg.get_composable_by_key(motion_key)

	while motions_reg.has_composable_with_prefix(motion_key) do
		local next_char = getchar_with_timeout(vim.o.timeoutlen)
		if not next_char then break end -- timeout, use current match
		if next_char == "\027" then break end -- ESC cancels, use current match

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

	motion_state.motion_key = motion_key
	motion_state.target_type = consts.TARGET_TYPES_BY_KEY[motion_key]

	-- Motion-based inference: look up a composable motion by motion_key.
	-- This allows any registered composable motion (w, b, e, j, k, s, f, etc.)
	-- to automatically work as a target for operators (d, y, c, p).
	-- If multi-char resolution already found a composable, use it directly.
	if not target_motion then
		target_motion = motions_reg.get_by_key(motion_key)
	end

	if target_motion and target_motion.composable then
		local motion = motion_state.motion
		if target_motion.extractor then motion.extractor = target_motion.extractor end
		if target_motion.filter then motion.filter = target_motion.filter end
		if target_motion.visualizer then motion.visualizer = target_motion.visualizer end
		if target_motion.collector then motion.collector = target_motion.collector end

		-- Merge target motion's metadata into motion_state
		if target_motion.metadata and target_motion.metadata.motion_state then
			for k, v in pairs(target_motion.metadata.motion_state) do
				motion_state[k] = v
			end
		end
	end

	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "extractor", "action", "visualizer", "filter" })

	-- Merge inferred module metadata into motion_state (setup.run merged metadata for the
	-- original motion, but infer may have overridden extractor/visualizer/filter/action)
	for _, module in pairs(modules) do
		if state.module_has_motion_state(module) then
			for k, v in pairs(module.metadata.motion_state) do
				motion_state[k] = v
			end
		end
	end

	if not modules.extractor or not modules.extractor.run then
		if motion_key == motion_state.motion.action_key then
			motion_state.target_type = "lines"

			-- NOTE: We might need to set motion_state here if actions ever need to set it
			-- Strip _jump suffix so delete_jump → delete_line, yank_jump → yank_line, etc.
			local action_name = modules.action.name:gsub("_jump$", "")
			local line_action =
				module_loader.get_module_by_name(ctx, cfg, motion_state, "actions", action_name .. "_line")

			if line_action and line_action.run then
				motion_state.selected_jump_target = targets.get_target_under_cursor(ctx, cfg, motion_state)

				if motion_state.selected_jump_target then
					line_action.run(ctx, cfg, motion_state)
					exit.throw(EXIT_TYPE.EARLY_EXIT)
				end
			end
		end

		-- Special case: R (treesitter search) called from operator context (yR, dR, cR).
		-- Call treesitter_search directly with the operator instead of feeding keys
		-- through operator-pending mode, which has timing issues with vim.schedule.
		if motion_key == "R" then
			require("smart-motion.actions.treesitter_search").run(nil, motion_state.motion.action_key)
			exit.throw(EXIT_TYPE.EARLY_EXIT)
		end

		-- Feed trigger key with noremap to get native operator behavior (avoids recursion),
		-- but feed the motion key with remap so user/plugin "o" mode keymaps fire (e.g. R).
		local resolved_trigger = vim.api.nvim_replace_termcodes(motion_state.motion.trigger_key, true, false, true)
		vim.api.nvim_feedkeys(resolved_trigger, "n", false)
		vim.api.nvim_feedkeys(motion_key, "m", false)
		exit.throw(EXIT_TYPE.EARLY_EXIT)
	end

end

return M
