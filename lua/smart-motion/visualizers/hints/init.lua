--- Module for hint generation and assignment.
local highlight = require("smart-motion.core.highlight")
local label_conflict = require("smart-motion.core.label_conflict")
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

--- Recalculates label counts based on a filtered key set.
---@param motion_state SmartMotionMotionState
---@param total_keys integer Number of available keys after filtering
local function recalculate_label_counts(motion_state, total_keys)
	local jump_target_count = motion_state.jump_target_count

	if jump_target_count <= total_keys then
		motion_state.single_label_count = jump_target_count
		motion_state.double_label_count = 0
		motion_state.sacrificed_keys_count = 0
	else
		local labels_needed = jump_target_count - total_keys
		local initial_sacrifice = math.ceil(math.sqrt(labels_needed))

		motion_state.double_label_count = labels_needed + initial_sacrifice

		local adjusted_sacrifice = math.ceil(math.sqrt(motion_state.double_label_count))

		motion_state.sacrificed_keys_count = math.max(initial_sacrifice, adjusted_sacrifice)
		motion_state.single_label_count = total_keys - motion_state.sacrificed_keys_count
	end

	motion_state.total_keys = total_keys
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

	-- Filter out conflicting labels when in search mode
	local effective_cfg = cfg
	if motion_state.is_searching_mode and motion_state.search_text and #motion_state.search_text > 0 then
		local filtered_keys = label_conflict.filter_conflicting_labels(cfg.keys, targets, ctx.bufnr)
		if #filtered_keys < #cfg.keys then
			-- Create a shallow copy of cfg with filtered keys
			effective_cfg = vim.tbl_extend("force", {}, cfg)
			effective_cfg.keys = filtered_keys
			-- Recalculate label counts based on new key pool
			recalculate_label_counts(motion_state, #filtered_keys)
		end
	end

	local label_pool = M.generate_hint_labels(ctx, effective_cfg, motion_state)

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
