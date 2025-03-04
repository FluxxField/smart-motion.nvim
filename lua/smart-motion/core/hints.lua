--- Module for hint generation and assignment.
local highlight = require("smart-motion.core.highlight")
local log = require("smart-motion.core.log")

local M = {}

--- Generates hint labels based on motion state.
-- Uses single-character labels first, and double-character labels if needed.
-- If there are more targets than labels, uses all available labels (graceful fallback).
---@param ctx table Full context (cursor position, buffer, etc.) — not used here, but part of standard signature.
---@param cfg table Validated config (keys, highlights, etc.) — needed for base_keys.
---@param motion_state table Current motion state (labels needed, direction, etc.)
---@return string[] Final ordered list of hint labels.
function M.generate_hint_labels(ctx, cfg, motion_state)
	if type(cfg.keys) ~= "table" or #cfg.keys == 0 then
		log.error("generate_hint_labels received invalid base_keys in cfg")
		return {}
	end

	local single_label_count = motion_state.single_label_count
	local extra_labels_needed = motion_state.extra_labels_needed

	local singles = vim.list_slice(cfg.keys, 1, single_label_count)
	local doubles = {}

	if extra_labels_needed > 0 then
		local double_base = vim.list_slice(cfg.keys, single_label_count + 1)

		for _, first in ipairs(double_base) do
			for _, second in ipairs(double_base) do
				table.insert(doubles, first .. second)

				if #doubles >= extra_labels_needed then
					break
				end
			end
			if #doubles >= extra_labels_needed then
				break
			end
		end

		if #doubles < extra_labels_needed then
			log.warn(
				string.format(
					"Needed %d double labels, but only generated %d! Label pool may be incomplete.",
					extra_labels_needed,
					#doubles
				)
			)
		end
	end

	local final_labels = vim.list_extend(singles, doubles)

	log.debug(string.format("Generated %d labels (singles: %d, doubles: %d)", #final_labels, #singles, #doubles))

	motion_state.hint_labels = final_labels

	return final_labels
end

--- Generates, assigns and applies labels in a single pass.
---@param ctx table Full context (cursor position, buffer, etc.).
---@param cfg table Validated config.
---@param motion_state table Current motion state (holds targets).
function M.assign_and_apply_labels(ctx, cfg, motion_state)
	local jump_targets = motion_state.jump_targets or {}
	local jump_target_count = motion_state.jump_target_count

	if jump_target_count == 0 then
		log.warn("assign_and_apply_labels: No targets to label")
		return
	end

	log.debug(string.format("Assigning and applying labels for %d targets", jump_target_count))

	local label_pool = M.generate_hint_labels(ctx, cfg, motion_state)

	if jump_target_count > #label_pool then
		log.debug(string.format("Only %d labels available, but %d targets found", #label_pool, jump_target_count))
	end

	highlight.dim_background(ctx, cfg, motion_state)

	for index, jump_target in ipairs(jump_targets) do
		local label = label_pool[index]

		if not label then
			break
		end

		if #label == 1 then
			highlight.apply_single_hint_label(ctx, cfg, motion_state, jump_target, label)
			motion_state.assigned_hint_labels[label] = { jump_target = jump_target, is_single_prefix = true }
		elseif #label == 2 then
			highlight.apply_double_hint_label(ctx, cfg, motion_state, jump_target, label, { dim_first_char = false })
			motion_state.assigned_hint_labels[label] = { jump_target = jump_target }
			motion_state.assigned_hint_labels[label:sub(1, 1)] = { is_double_prefix = true }
		else
			log.error("Unexpected hint length for label: '" .. label .. "'")
		end
	end
end

return M
