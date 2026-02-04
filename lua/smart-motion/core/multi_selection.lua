--- Multi-selection mode: toggle multiple targets with label keys, confirm with Enter.
local consts = require("smart-motion.consts")
local highlight = require("smart-motion.core.highlight")
local log = require("smart-motion.core.log")

local M = {}

--- Redraws hints with selected targets highlighted differently.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param selected table<string, boolean>
function M._redraw_with_selections(ctx, cfg, motion_state, selected)
	highlight.clear(ctx, cfg, motion_state)
	highlight.dim_background(ctx, cfg, motion_state)

	local targets = motion_state.jump_targets or {}
	local label_pool = motion_state.hint_labels or {}

	for index, target in ipairs(targets) do
		local label = label_pool[index]
		if not label or not target then
			break
		end

		if selected[label] then
			-- Selected: use SmartMotionSelected highlight via extmark
			local bufnr = (target.metadata and target.metadata.bufnr) or ctx.bufnr
			motion_state.affected_buffers = motion_state.affected_buffers or {}
			motion_state.affected_buffers[bufnr] = true

			local row = target.start_pos.row
			local col = target.start_pos.col
			local end_col = target.end_pos.col

			-- Clamp col to line length
			local line_text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
			if line_text then
				col = math.min(col, #line_text)
				end_col = math.min(end_col, #line_text)
			end

			-- Highlight the selected target text
			vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, row, col, {
				end_col = end_col,
				hl_group = "SmartMotionSelected",
			})

			-- Also show the label overlaid
			vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, row, col, {
				virt_text = { { label, "SmartMotionSelected" } },
				virt_text_pos = "overlay",
				hl_mode = "combine",
			})
		else
			-- Not selected: render normal hint
			if #label == 1 then
				highlight.apply_single_hint_label(ctx, cfg, motion_state, target, label)
			elseif #label == 2 then
				highlight.apply_double_hint_label(ctx, cfg, motion_state, target, label)
			end
		end
	end

	vim.cmd("redraw")
end

--- Waits for user to toggle multiple targets via label keys.
--- Enter confirms, ESC cancels.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@return table[]|nil Selected targets sorted in reverse position order, or nil on cancel.
function M.wait_for_multi_selection(ctx, cfg, motion_state)
	local selected = {} -- label → true toggle map

	while true do
		local char = vim.fn.getcharstr()

		-- ESC cancels
		if char == "\027" or char == "" then
			return nil
		end

		-- Enter confirms
		if char == "\r" then
			break
		end

		local entry = motion_state.assigned_hint_labels[char]

		if entry and entry.is_single_prefix and entry.target then
			-- Toggle single-char label
			if selected[char] then
				selected[char] = nil
			else
				selected[char] = true
			end
			M._redraw_with_selections(ctx, cfg, motion_state, selected)
		elseif entry and entry.is_double_prefix then
			-- Wait for second char
			local char2 = vim.fn.getcharstr()
			if char2 == "\027" or char2 == "" then
				return nil
			end

			local full = char .. char2
			local entry2 = motion_state.assigned_hint_labels[full]
			if entry2 and entry2.target then
				if selected[full] then
					selected[full] = nil
				else
					selected[full] = true
				end
				M._redraw_with_selections(ctx, cfg, motion_state, selected)
			end
		end
	end

	-- Collect selected targets
	local selected_targets = {}
	for label, _ in pairs(selected) do
		local entry = motion_state.assigned_hint_labels[label]
		if entry and entry.target then
			table.insert(selected_targets, entry.target)
		end
	end

	if #selected_targets == 0 then
		return nil
	end

	-- Sort reverse (bottom-right first) for safe sequential editing
	table.sort(selected_targets, function(a, b)
		if a.start_pos.row ~= b.start_pos.row then
			return a.start_pos.row > b.start_pos.row
		end
		return a.start_pos.col > b.start_pos.col
	end)

	return selected_targets
end

return M
