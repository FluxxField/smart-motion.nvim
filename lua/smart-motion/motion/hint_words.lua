--- Word motion handler.
local consts = require("smart-motion.consts")
local state = require("smart-motion.core.state")
local utils = require("smart-motion.utils")
local hints = require("smart-motion.core.hints")
local selection = require("smart-motion.core.selection")
local targets = require("smart-motion.core.targets")
local flow_state = require("smart-motion.core.flow-state")
local lines_collector = require("smart-motion.collectors.lines")
local words_extractor = require("smart-motion.extractors.words")
local log = require("smart-motion.core.log")

local M = {}

--- Public method: Hints words from the possible jump targets in a given direction.
---@param direction "before_cursor"|"after_cursor"
---@param hint_position "start"|"end"
function M.run(direction, hint_position)
	log.debug(string.format("Highlighting word - direction: %s, hint_position: %s", direction, hint_position))

	--
	-- Gather Context
	--
	local ctx, cfg, motion_state = utils.prepare_motion(direction, hint_position, consts.TARGET_TYPES.WORD, true)
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
	-- Calculate Lines (Streaming)
	--
	local lines_generator = lines_collector.init()
	if not lines_generator then
		log.debug("No lines to search - exiting early")
		return
	end

	--
	-- Extract Words (Streaming)
	--
	local words_generator = words_extractor.init(lines_generator)
	if not words_generator then
		log.debug("No words found in lines - existing early")
		return
	end

	--
	-- Build Jump Targets
	--
	targets.get_jump_targets(ctx, cfg, motion_state, words_generator)

	state.finalize_motion_state(motion_state)

	--
	-- Handle Flow State
	--
	if flow_state.evaluate_flow_at_motion_start() then
		if motion_state.selected_jump_target then
			utils.jump_to_target(ctx, cfg, motion_state)
			utils.reset_motion(ctx, cfg, motion_state)
			return
		end
	end

	--
	-- Assign Hints and Apply Hints
	--
	hints.assign_and_apply_labels(ctx, cfg, motion_state)

	--
	-- Wait for Selection
	--
	local jumped_early = selection.wait_for_hint_selection(ctx, cfg, motion_state)

	if jumped_early then
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	if motion_state.selected_jump_target then
		log.debug(
			string.format(
				"Jumped to target - line: %d, col: %d",
				motion_state.selected_jump_target.row,
				motion_state.selected_jump_target.col
			)
		)

		utils.jump_to_target(ctx, cfg, motion_state)
	else
		log.debug("User cancelled selection - resetting flow")
		flow_state.reset()                       -- Cancelled = full flow break
		utils.reset_motion(ctx, cfg, motion_state) -- Always clear extmarks
	end
end

return M
