local log = require("smart-motion.core.log")
local highlight = require("smart-motion.core.highlight")
local consts = require("smart-motion.consts")

local HINT_POSITION = consts.HINT_POSITION

---@type SmartMotionRegistry<SmartMotionSelectionHandlerEntry>
local selection_handlers = require("smart-motion.core.registry")("selection_handlers")

--- Re-renders all assigned hint labels using the current motion_state.
--- Follows the same clear→dim→apply→redraw pattern as highlight.filter_double_hints.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
local function rerender_hints(ctx, cfg, motion_state)
	highlight.clear(ctx, cfg, motion_state)
	highlight.dim_background(ctx, cfg, motion_state)

	for label, entry in pairs(motion_state.assigned_hint_labels) do
		local target = entry.target
		if target then
			if entry.is_single_prefix then
				highlight.apply_single_hint_label(ctx, cfg, motion_state, target, label)
			elseif #label == 2 then
				highlight.apply_double_hint_label(ctx, cfg, motion_state, target, label)
			end
		end
	end

	vim.cmd("redraw")
end

---@type table<string, SmartMotionSelectionHandlerEntry>
local handler_entries = {
	select_first = {
		run = function(ctx, cfg, motion_state)
			-- selected_jump_target is already set to targets[1] by targets.get_targets(),
			-- so just return true to accept the pre-set default.
			return true
		end,
		metadata = {
			label = "Select First",
			description = "Selects the first (closest) target during label selection",
		},
	},

	select_last = {
		run = function(ctx, cfg, motion_state)
			local targets = motion_state.jump_targets
			if targets and #targets > 0 then
				motion_state.selected_jump_target = targets[#targets]
			end
			return true
		end,
		metadata = {
			label = "Select Last",
			description = "Selects the last (furthest) target during label selection",
		},
	},

	toggle_hint_position = {
		run = function(ctx, cfg, motion_state)
			-- Flip between start and end
			if motion_state.hint_position == HINT_POSITION.START then
				motion_state.hint_position = HINT_POSITION.END
			else
				motion_state.hint_position = HINT_POSITION.START
			end

			log.debug("Toggled hint_position to " .. motion_state.hint_position)
			rerender_hints(ctx, cfg, motion_state)

			-- Return false to stay in selection loop (wait for next keypress)
			return false
		end,
		metadata = {
			label = "Toggle Hint Position",
			description = "Toggles hint labels between start and end of targets",
		},
	},
}

selection_handlers.register_many(handler_entries)

return selection_handlers
