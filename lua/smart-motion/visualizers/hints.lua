--- Module for hint generation and assignment.
local highlight = require("smart-motion.core.highlight")
local log = require("smart-motion.core.log")

---@type SmartMotionVisualizerModuleEntry
local M = {}

--- Generates hint labels based on motion state.
-- Uses single-character labels first, and double-character labels if needed.
-- If there are more targets than labels, uses all available labels (graceful fallback).
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@return string[] Final ordered list of hint labels.
function M.generate_hint_labels(ctx, cfg, motion_state)
	if type(cfg.keys) ~= "table" or #cfg.keys == 0 then
		log.error("generate_hint_labels received invalid base_keys in cfg")
		return {}
	end

	local single_label_count = motion_state.single_label_count
	local double_label_count = motion_state.double_label_count

	local singles = vim.list_slice(cfg.keys, 1, single_label_count)
	local doubles = {}

	if double_label_count > 0 then
		local double_base = vim.list_slice(cfg.keys, single_label_count + 1)

		for _, first in ipairs(double_base) do
			for _, second in ipairs(double_base) do
				table.insert(doubles, first .. second)

				if #doubles >= double_label_count then
					break
				end
			end

			if #doubles >= double_label_count then
				break
			end
		end

		if #doubles < double_label_count then
			log.debug(
				string.format(
					"Needed %d double labels, but only generated %d! Label pool may be incomplete.",
					double_label_count or 0,
					#doubles or 0
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
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local targets = motion_state.jump_targets or {}

	if #targets == 0 then
		log.debug("hints: not targets, exiting")
		return
	end

	if motion_state.sort_by then
		local sort_by_key = motion_state.sort_by
		local descending = motion_state.sort_descending == true

		table.sort(targets, function(a, b)
			local a_weight = a.metadata and a.metadata[sort_by_key] or math.huge
			local b_weight = b.metadata and b.metadata[sort_by_key] or math.huge

			if descending then
				return a_weight > b_weight
			else
				return a_weight < b_weight
			end
		end)
	end

	local label_pool = M.generate_hint_labels(ctx, cfg, motion_state)

	if #targets > #label_pool then
		log.debug(string.format("Only %d labels available, but %d targets found", #label_pool, #targets))
	end

	highlight.clear(ctx, cfg, motion_state)
	highlight.dim_background(ctx, cfg, motion_state)

	for index, target in ipairs(targets) do
		local label = label_pool[index]

		if not label or not target then
			break
		end

		if #label == 1 then
			highlight.apply_single_hint_label(ctx, cfg, motion_state, target, label)
			motion_state.assigned_hint_labels[label] = { target = target, is_single_prefix = true }
		elseif #label == 2 then
			highlight.apply_double_hint_label(ctx, cfg, motion_state, target, label)
			motion_state.assigned_hint_labels[label] = { target = target }
			motion_state.assigned_hint_labels[label:sub(1, 1)] = { is_double_prefix = true }
		else
			log.error("Unexpected hint length for label: '" .. label .. "'")
		end
	end

	vim.cmd("redraw")
end

return M
