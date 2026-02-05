local exit = require("smart-motion.core.events.exit")
local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionVisualizerModuleEntry
local M = {}

--- Convert targets to quickfix list format and open quickfix window
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local targets = motion_state.jump_targets or {}

	if #targets == 0 then
		exit.throw(EXIT_TYPE.EARLY_EXIT)
		return
	end

	local qflist = {}
	for _, target in ipairs(targets) do
		local bufnr = target.metadata and target.metadata.bufnr or ctx.bufnr
		local filename = vim.api.nvim_buf_get_name(bufnr)

		-- Get the full line text for context
		local line_text = ""
		local lines = vim.api.nvim_buf_get_lines(bufnr, target.start_pos.row, target.start_pos.row + 1, false)
		if lines and lines[1] then
			line_text = lines[1]
		end

		table.insert(qflist, {
			bufnr = bufnr,
			filename = filename ~= "" and filename or nil,
			lnum = target.start_pos.row + 1, -- 1-indexed
			col = target.start_pos.col + 1, -- 1-indexed
			text = target.text or line_text,
		})
	end

	-- Set the quickfix/location list with a title
	local title = "SmartMotion Targets"
	if motion_state.motion and motion_state.motion.trigger_key then
		title = title .. " [" .. motion_state.motion.trigger_key .. "]"
	end

	local use_loclist = motion_state.use_loclist
	if use_loclist then
		vim.fn.setloclist(ctx.winid, {}, "r") -- Clear existing
		vim.fn.setloclist(ctx.winid, qflist, "a")
		vim.fn.setloclist(ctx.winid, {}, "a", { title = title })
		vim.cmd("lopen")
	else
		vim.fn.setqflist({}, "r") -- Clear existing
		vim.fn.setqflist(qflist, "a")
		vim.fn.setqflist({}, "a", { title = title })
		vim.cmd("copen")
	end

	-- Don't proceed to selection - user will navigate with :cnext/:cprev
	exit.throw(EXIT_TYPE.EARLY_EXIT)
end

M.metadata = {
	label = "Quickfix Visualizer",
	description = "Populates quickfix list with targets for navigation",
	motion_state = {
		dim_background = false,
	},
}

return M
