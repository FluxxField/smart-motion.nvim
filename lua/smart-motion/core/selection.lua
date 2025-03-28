local log = require("smart-motion.core.log")
local highlight = require("smart-motion.core.highlight")
local consts = require("smart-motion.consts")
local flow_state = require("smart-motion.core.flow-state")

local M = {}

--- Waits for the user to press a hint key and handles both single and double character hints.
---@param ctx table Motion context (bufnr, etc.)
---@param cfg table Validated configuration
---@param motion_state table Current motion state (holds assigned hints)
function M.wait_for_hint_selection(ctx, cfg, motion_state)
	log.debug("Waiting for user hint selection (mode: " .. tostring(motion_state.selection_mode) .. ")")

	if type(motion_state.assigned_hint_labels) ~= "table" or vim.tbl_isempty(motion_state.assigned_hint_labels) then
		log.debug("wait_for_hint_selection called with invalid or empty assigned_hint_labels")
		return
	end

	local char = vim.fn.getcharstr()

	if char == "" or flow_state.should_cancel_on_keypress(char) then
		log.debug("Selection cancelled by key: " .. char .. " - exiting flow")
		flow_state.exit_flow()
		motion_state.selected_jump_target = nil

		return
	end

	if flow_state.evaluate_flow_at_selection() then
		log.debug("Selection is jumping early")
		return
	end

	if motion_state.selection_mode == consts.SELECTION_MODE.FIRST then
		local entry = motion_state.assigned_hint_labels[char]

		if entry then
			if #char == 1 and entry.is_single_prefix then
				log.debug("User selected single-char hint: " .. char)
				motion_state.selected_jump_target = entry.jump_target
				return
			end

			if #char == 1 and entry.is_double_prefix then
				-- Enter second character selection phase
				motion_state.selection_mode = consts.SELECTION_MODE.SECOND
				motion_state.selection_first_char = char

				-- Filter and update highlights to show only matching second chars
				highlight.filter_double_hints(ctx, cfg, motion_state, char)

				log.debug("Entering double-char mode after selecting first char: " .. char)

				-- Immediately recurse to handle the second char (simpler for caller)
				return M.wait_for_hint_selection(ctx, cfg, motion_state)
			end
		end

		log.debug("No matching hint found for input: " .. char)
		motion_state.selected_jump_target = nil
		return
	elseif motion_state.selection_mode == consts.SELECTION_MODE.SECOND then
		local first_char = motion_state.selection_first_char
		local full_hint = first_char .. char

		local entry = motion_state.assigned_hint_labels[full_hint]

		if entry then
			log.debug("User completed double-char selection: " .. full_hint)
			motion_state.selected_jump_target = entry.jump_target
			return
		end

		log.debug("No matching double-char hint found for input: " .. full_hint)
		motion_state.selected_jump_target = nil
		return
	end

	log.error("Unexpected selection state mode: " .. tostring(motion_state.selection_mode))
	motion_state.selected_jump_target = nil
end

return M
