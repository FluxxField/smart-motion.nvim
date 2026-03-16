local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Transforms pair data into SmartMotionTargets based on pair_scope and is_surround.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @param data table Pair data from the pairs collector
--- @return table|nil Target object
function M.run(ctx, cfg, motion_state, data)
	local pair_scope = motion_state.pair_scope or "inside"
	local is_surround = motion_state.is_surround or false

	if is_surround then
		-- Surround mode: target spans full pair, delimiter positions preserved in metadata
		return {
			text = data.full_text,
			start_pos = { row = data.open_pos.start.row, col = data.open_pos.start.col },
			end_pos = { row = data.close_pos["end"].row, col = data.close_pos["end"].col },
			type = "pairs",
			metadata = {
				open_pos = data.open_pos,
				close_pos = data.close_pos,
				pair_open = data.pair_open,
				pair_close = data.pair_close,
				is_surround = true,
				-- Pass through extra fields from collectors (func_name, tag_name, etc.)
				func_name = data.func_name,
				tag_name = data.tag_name,
			},
		}
	elseif pair_scope == "around" then
		-- Around mode: target spans open start to close end
		return {
			text = data.full_text,
			start_pos = { row = data.open_pos.start.row, col = data.open_pos.start.col },
			end_pos = { row = data.close_pos["end"].row, col = data.close_pos["end"].col },
			type = "pairs",
			metadata = {
				pair_open = data.pair_open,
				pair_close = data.pair_close,
			},
		}
	else
		-- Inside mode: target spans content between delimiters
		return {
			text = data.content_text,
			start_pos = { row = data.open_pos["end"].row, col = data.open_pos["end"].col },
			end_pos = { row = data.close_pos.start.row, col = data.close_pos.start.col },
			type = "pairs",
			metadata = {
				pair_open = data.pair_open,
				pair_close = data.pair_close,
			},
		}
	end
end

M.metadata = {
	label = "Pairs Extractor",
	description = "Transforms pair data into targets based on scope (inside/around/surround)",
}

return M
