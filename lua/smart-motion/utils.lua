--- General-purpose utilities.
local log = require("smart-motion.core.log")
local context = require("smart-motion.core.context")
local state = require("smart-motion.core.state")
local config = require("smart-motion.config")
local highlight = require("smart-motion.core.highlight")
local consts = require("smart-motion.consts")
local history = require("smart-motion.core.history")
local exit = require("smart-motion.core.events.exit")

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

--- Prepares the motion by gathering context, config, and initializing state.
---@return SmartMotionContext?, SmartMotionConfig?, SmartMotionMotionState?
function M.prepare_motion()
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

	local motion_state = state.create_motion_state()

	return ctx, cfg, motion_state
end

--- Resets the motion by clearing highlights, closing floating windows, and clearing dynamic state.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.reset_motion(ctx, cfg, motion_state)
	-- Only add to history if we have a selected target
	if motion_state.selected_jump_target then
		if motion_state.motion and motion_state.motion.action == "run_motion" then
			history.add({
				motion = motion_state.selected_jump_target.motion,
				target = motion_state.selected_jump_target,
				metadata = {
					time_stamp = os.time(),
				},
			})
		else
			history.add({
				motion = motion_state.motion,
				target = motion_state.selected_jump_target,
				metadata = {
					time_stamp = os.time(),
				},
			})
		end
	end

	-- Save char state for ;/, repeat if this was an f/F/t/T motion
	local trigger_key = motion_state.motion and motion_state.motion.trigger_key
	if trigger_key and vim.tbl_contains({ "f", "F", "t", "T" }, trigger_key) then
		local search_text = motion_state.search_text
		if search_text and search_text ~= "" then
			local char_state = require("smart-motion.search.char_state")
			char_state.save(search_text, motion_state.direction, motion_state.exclude_target or false)
		end
	end

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
			end

			while true do
				local ok, data = exit.safe(coroutine.resume(input_gen, ctx, cfg, motion_state))
				exit.throw_if(not ok, EXIT_TYPE.EARLY_EXIT)

				if data == nil then
					break
				end

				local result = run_fn(ctx, cfg, motion_state, data)

				if type(result) == "thread" then
					while true do
						local ok2, yielded_target = exit.safe(coroutine.resume(result))
						exit.throw_if(not ok2, EXIT_TYPE.EARLY_EXIT)

						if yielded_target == nil then
							break
						end

						coroutine.yield(yielded_target)
					end
				elseif type(result) == "table" then
					coroutine.yield(result)
				end
			end
		end)
	end
end

return M
