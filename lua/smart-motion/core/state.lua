--- Module for tracking motion state.
local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

--- @class SmartMotionMotionState
--- @field total_keys integer
--- @field max_lines integer
--- @field max_labels integer
--- @field direction Direction
--- @field hint_position HintPosition
--- @field target_type TargetType
--- @field ignore_whitespace boolean

-- Target tracking
--- @field jump_target_count integer
--- @field jump_targets JumpTarget[]  -- Replace `any` with a concrete `JumpTarget` type later
--- @field selected_jump_target? JumpTarget

-- Hint labeling
--- @field hint_labels string[]  -- Possibly just strings or label metadata?
--- @field assigned_hint_labels table<string, HintEntry>

-- Label logic
--- @field single_label_count integer
--- @field double_label_count integer
--- @field sacrificed_keys_count integer

-- Selection
--- @field selection_mode SelectionMode
--- @field selection_first_char? string

local M = {}

M.static = {}

--- Initializes static key-based state once when config is verified.
---@param cfg table Full user config
function M.init_motion_state(cfg)
	if type(cfg.keys) ~= "table" or #cfg.keys == 0 then
		log.error("init_motion_state received invalid keys: expected non-empty table")

		return
	end

	local keys_squared = #cfg.keys * #cfg.keys

	M.static = {
		total_keys = #cfg.keys,
		max_labels = keys_squared,
		max_lines = keys_squared,
	}

	log.debug(
		string.format(
			"Static state initialized - total_keys: %d, max_labels: %d, max_lines: %d",
			M.static.total_keys,
			M.static.max_lines,
			M.static.max_labels
		)
	)
end

--- Creates a fresh motion state (per motion)
---@param direction Direction
---@param hint_position HintPosition
---@param target_type TargetType
---@param ignore_whitespace boolean
---@return SmartMotionMotionState
function M.create_motion_state(direction, hint_position, target_type, ignore_whitespace)
	---@type SmartMotionMotionState
	return {
		total_keys = M.static.total_keys,
		max_lines = M.static.max_lines,
		max_labels = M.static.max_labels,

		-- Motion Intent
		direction = direction,
		hint_position = hint_position,
		target_type = target_type,
		ignore_whitespace = ignore_whitespace,

		-- Motion-specific data (starts empty)
		jump_target_count = 0,
		jump_targets = {},
		hint_labels = {},
		assigned_hint_labels = {},

		-- Label calculations
		single_label_count = 0,
		double_label_count = 0,
		sacrificed_keys_count = 0,

		-- Selection
		selection_mode = consts.SELECTION_MODE.FIRST,
		selection_first_char = nil,
		selected_jump_target = nil,
	}
end

--- Finalizes the motion state after target collection.
---@param motion_state SmartMotionMotionState
function M.finalize_motion_state(motion_state)
	if motion_state.total_keys == 0 then
		log.error("finalize_motion_state called before static state was initialized")
		return
	end

	local jump_target_count = #motion_state.jump_targets
	motion_state.jump_target_count = jump_target_count

	if type(jump_target_count) ~= "number" or jump_target_count < 0 then
		log.error("finalize_motion_state received invalid jump_target_count: " .. tostring(jump_target_count))
		return
	end

	if jump_target_count <= M.static.total_keys then
		-- We only need singles
		motion_state.single_label_count = jump_target_count
		motion_state.double_label_count = 0
		motion_state.sacrificed_keys_count = 0
	else
		local labels_needed = jump_target_count - motion_state.total_keys
		local initial_sacrifice = math.ceil(math.sqrt(labels_needed))

		motion_state.double_label_count = labels_needed + initial_sacrifice

		local adjusted_sacrifice = math.ceil(math.sqrt(motion_state.double_label_count))

		motion_state.sacrificed_keys_count = math.max(initial_sacrifice, adjusted_sacrifice)
		motion_state.single_label_count = motion_state.total_keys - motion_state.sacrificed_keys_count
	end

	log.debug(
		string.format(
			"Motion state finalized - jump_targets: %d, singles: %d, doubles: %d, sacrificed_keys: %d",
			motion_state.jump_target_count,
			motion_state.single_label_count,
			motion_state.double_label_count,
			motion_state.sacrificed_keys_count
		)
	)
end

function M.reset(motion_state)
	motion_state.single_label_count = 0
	motion_state.double_label_count = 0
	motion_state.sacrificed_keys_count = 0

	motion_state.jump_target_count = 0
	motion_state.jump_targets = {}
	motion_state.hint_labels = {}
	motion_state.assigned_hint_labels = {}

	motion_state.selection_mode = consts.SELECTION_MODE.FIRST
	motion_state.selection_first_char = nil
	motion_state.selected_jump_target = nil
end

return M
