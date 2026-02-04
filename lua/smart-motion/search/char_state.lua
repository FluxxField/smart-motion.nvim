--- Stores the last f/F/t/T char motion state for ;/, repeat.
local M = {}

M.last = nil

--- Save the last char motion state.
---@param search_text string
---@param direction Direction
---@param exclude_target boolean
function M.save(search_text, direction, exclude_target)
	M.last = {
		search_text = search_text,
		direction = direction,
		exclude_target = exclude_target or false,
	}
end

---@return table|nil
function M.get()
	return M.last
end

return M
