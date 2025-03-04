local M = {}

local words_collector = require("smart-motion.jump_target_collectors.words")

--- Returns a function that can generate targets when called with context, config, and state.
---@param target_type string The type of target to collect (e.g., "word", "char").
function M.get_jump_target_collector_for_type(target_type)
	if target_type == "word" then
		return words_collector.generate_jump_targets_from_words
	else
		error("Unsupported target type: " .. target_type)
	end
end

return M
