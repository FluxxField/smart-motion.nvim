--- General-purpose utilities.
local log = require("smart-motion.core.log")
local context = require("smart-motion.core.context")
local state = require("smart-motion.core.state")
local config = require("smart-motion.config")
local highlight = require("smart-motion.core.highlight")
local consts = require("smart-motion.consts")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

--- Closes all diagnostic and completion floating windows.
function M.close_floating_windows()
	log.debug("Closing floating windows (diagnostics & completion)")

	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		local ok, win_config = pcall(vim.api.nvim_win_get_config, winid)

		if not ok then
			log.debug("Failed to get window config for winid: " .. tostring(winid))

			goto continue
		end

		if vim.tbl_contains({ "cursor", "win" }, win_config.relative) then
			local success, err = pcall(vim.api.nvim_win_close, winid, true)

			if not success then
				log.debug(string.format("Failed to close floating window %d: %s", winid, err))
			end
		end

		::continue::
	end

	log.debug("Floating window cleanup complete")
end

--- Waits for the user to press a hint key and returns the associated jump target.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@return any|nil
function M.wait_for_hint_selection(ctx, cfg, motion_state)
	log.debug("Waiting for user hint selection")

	if type(motion_state.assigned_hint_labels) ~= "table" or vim.tbl_isempty(motion_state.assigned_hint_labels) then
		log.error("wait_for_hint_selection called with invalid or empty motion_state.assigned_hint_labels table")

		return nil
	end

	local char = vim.fn.getcharstr()

	if char == "" then
		log.debug("User pressed nothing - selection cancelled")

		return nil
	end

	local entry = motion_state.assigned_hint_labels[char]

	if entry and entry.target then
		log.debug("User selected hint: " .. vim.inspect(entry.target))

		return entry.target
	else
		log.debug("No matching hint found for input: " .. char)

		return nil
	end
end

--- Prepares the motion by gathering context, config, and initializing state.
---@param target_type TargetType
---@return SmartMotionContext?, SmartMotionConfig?, SmartMotionMotionState?
function M.prepare_motion(target_type)
	local ctx = context.get()
	local cfg = config.validated

	if not cfg or type(cfg) ~= "table" then
		log.error("prepare_motion: Config is missing or invalid")
		return nil, nil, nil
	end

	if type(cfg.keys) ~= "table" or #cfg.keys == 0 then
		log.error("prepare_motion: Config `keys` is missing or improperly formatted")
		return nil, nil, nil
	end

	local motion_state = state.create_motion_state(target_type)

	return ctx, cfg, motion_state
end

--- Resets the motion by clearing highlights, closing floating windows, and clearing dynamic state.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.reset_motion(ctx, cfg, motion_state)
	-- Clear any virtual text and extmarks.
	highlight.clear(ctx, cfg, motion_state)

	-- Close floating windows (if you have a function for that).
	M.close_floating_windows()

	-- Reset dynamic parts of the motion state.
	motion_state = state.reset(motion_state)
end

--- Checks if a string is non-empty and non-whitespace.
---@param s any
---@return boolean
function M.is_non_empty_string(s)
	return type(s) == "string" and s:gsub("%s+", "") ~= ""
end

--
-- Module Wrapper
--
function M.module_wrapper(run_fn, opts)
	opts = opts or {}

	return function(input_gen)
		return coroutine.create(function(ctx, cfg, motion_state)
			if opts.before_input_loop then
				local result = opts.before_input_loop(ctx, cfg, motion_state)

				if type(result) == "string" then
					motion_state.exit_type = result

					if motion_state.exit_type == EXIT_TYPE.EARLY_EXIT then
						return
					end
				end
			end

			while true do
				if motion_state.exit_type == EXIT_TYPE.EARLY_EXIT then
					break
				end

				local ok, data = coroutine.resume(input_gen, ctx, cfg, motion_state)

				if not ok then
					log.error("Input Generator Coroutine Error: " .. tostring(data))
					break
				end

				if data == nil then
					break
				end

				local result = run_fn(ctx, cfg, motion_state, data)

				if type(result) == "thread" then
					while true do
						local ok2, yielded_target = coroutine.resume(result)
						if not ok2 then
							break
						end

						if yielded_target == nil then
							break
						end

						coroutine.yield(yielded_target)
					end
				elseif type(result) == "table" then
					coroutine.yield(result)
				elseif type(result) == "string" then
					motion_state.exit_type = result
				end
			end
		end)
	end
end

return M
