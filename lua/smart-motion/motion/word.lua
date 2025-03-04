-- Universal SmartMotion Flow
-- Gather Context - Cursor position, buffer number, direction, etc
-- Initial Cleanup - Clear floating windows and clear highlighting
-- Handle Spam - If a spammable motion, handle it
-- Collect Targets - Call a shared `get_jump_targets()` function (with target type: word, char, line, etc...)
-- Generate Hints - Call a shared `generate_hint_labels()` to compute labels
-- Assign Hints to Targets - Apply the hints (reusing the same logic for all motions)
-- Apply Highlights - Use a unified highlight function that works for any motion type
-- Wait for Selection - Use `getcharstr()` or similar to wait for user selection
-- Execute Jump - Move cursor to selected target
-- Clear Highlights - Remove all hints after action completes

--- Word motion handler.
local consts = require("smart-motion.consts")
local state = require("smart-motion.core.state")
local utils = require("smart-motion.utils")
local hints = require("smart-motion.core.hints")
local spam = require("smart-motion.core.spam")
local lines_module = require("smart-motion.core.lines")
local selection = require("smart-motion.core.selection")
local targets = require("smart-motion.core.targets")
local log = require("smart-motion.core.log")

local M = {}

--- Public method: Hints words from the possible jump targets in a given direction.
---@param direction "before_cursor"|"after_cursor"
---@param hint_position "start"|"end"
---@param is_spammable boolean|nil Optional, allows skipping highlighting if user is spamming the trigger key.
function M.hint_words(direction, hint_position, is_spammable)
	log.debug(
		string.format(
			"Highlighting word - direction: %s, hint_position: %s, is_spammable: %s",
			direction,
			hint_position,
			tostring(is_spammable)
		)
	)

	--
	-- Gather Context
	--
	local ctx, cfg, motion_state = utils.prepare_motion(direction, hint_position, consts.TARGET_TYPES.WORD)
	if not ctx or not cfg or not motion_state then
		log.error("hint_words: Failed to prepare motion - aborting")

		return
	end

	--
	-- Initial Cleanup
	-- Resets the motion by clearing highlights, closing floating windows
	-- clearing spam tracking, and resetting the dynamic state
	--
	utils.reset_motion(ctx, cfg, motion_state)

	--
	-- Calculate Lines
	--
	local lines = lines_module.get_lines_for_motion(ctx, cfg, motion_state)
	if not lines or #lines == 0 then
		log.debug("No lines to search - exiting early")

		return
	end

	--
	-- Get target generator
	--
	local generator = targets.get_jump_target_collector_for_type(motion_state.target_type)

	if not generator then
		return
	end

	local collector, first_jump_target = generator(ctx, cfg, motion_state, {})
	--
	-- Handle spam detection
	--
	local spam_key = direction .. "-" .. hint_position

	if is_spammable and spam.is_spam(spam_key) then
		log.debug(string.format("Spamming detected - executing native motion for: %s", spam_key))

		spam.handle_word_motion_spam(ctx, cfg, motion_state)

		return
	end

	--
	-- Collect Targets
	--
	local jump_targets = {}

	if first_jump_target then
		table.insert(jump_targets, first_jump_target)
	end

	while true do
		local ok, jump_target = coroutine.resume(collector, ctx, cfg, motion_state)

		if not ok or not jump_target then
			break
		end

		table.insert(jump_targets, jump_target)
	end

	motion_state.jump_targets = jump_targets

	state.finalize_motion_state(motion_state)

	--
	-- Assign Hints and Apply Hints
	--
	hints.assign_and_apply_labels(ctx, cfg, motion_state)

	--
	-- Wait for Selection
	--
	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	--
	-- Execute Jump
	--
	if motion_state.selected_jump_target then
		utils.jump_to_target(ctx, cfg, motion_state)

		log.debug(
			string.format(
				"Jumped to target - line: %d, col: %d",
				motion_state.selected_jump_target.row,
				motion_state.selected_jump_target.col
			)
		)
	else
		log.debug("No target selected - user cancelled")
	end

	--
	-- Clear Everything
	--
	utils.reset_motion(ctx, cfg, motion_state)

	log.debug("Word motion complete")
end

return M
