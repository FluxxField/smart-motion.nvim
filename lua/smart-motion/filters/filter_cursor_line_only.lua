local log = require("smart-motion.core.log")

---@type SmartMotionFilterModuleEntry
local M = {}

--- Cursor Line Only Filter
-- Keeps only targets that are on the same line as the cursor.
-- @type SmartMotionFilterModuleEntry
function M.run(extractor_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local cursor_row = ctx.cursor_line

		while true do
			local ok, target = coroutine.resume(extractor_gen, ctx, cfg, motion_state)

			if not ok then
				log.error("Extractor Coroutine Error: " .. tostring(target))
				break
			end

			if target == nil then
				break
			end

			if target.start_pos.row == cursor_row then
				coroutine.yield(target)
			end
		end
	end)
end

return M
