-- Shared test utilities for smart-motion.nvim integration tests

local M = {}

--- Default test config that disables timing-dependent features
M.test_config = {
	keys = "fjdksleirughtynm",
	flow_state_timeout_ms = 0,
	native_search = false,
	auto_select_target = false,
	dim_background = false,
	presets = {},
}

--- Setup the plugin with optional config overrides
---@param overrides? table
function M.setup_plugin(overrides)
	local config = vim.tbl_deep_extend("force", vim.deepcopy(M.test_config), overrides or {})
	require("smart-motion").setup(config)
end

--- Create a scratch buffer with the given lines and set it as current
---@param lines string[]
---@return integer bufnr
function M.create_buf(lines)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(bufnr)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].filetype = "text"
	return bufnr
end

--- Set cursor position (1-indexed row, 0-indexed col)
---@param row integer
---@param col integer
function M.set_cursor(row, col)
	vim.api.nvim_win_set_cursor(0, { row, col })
end

--- Get cursor position (1-indexed row, 0-indexed col)
---@return integer row, integer col
function M.get_cursor()
	local pos = vim.api.nvim_win_get_cursor(0)
	return pos[1], pos[2]
end

--- Get the contents of a register
---@param reg string
---@return string
function M.get_register(reg)
	return vim.fn.getreg(reg)
end

--- Get all lines from the current buffer
---@return string[]
function M.get_buf_lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

--- Build a minimal SmartMotionContext
---@param overrides? table
---@return SmartMotionContext
function M.build_ctx(overrides)
	local bufnr = vim.api.nvim_get_current_buf()
	local winid = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(winid)
	local last_line = vim.api.nvim_buf_line_count(bufnr)

	local ctx = {
		bufnr = bufnr,
		winid = winid,
		cursor_line = cursor[1] - 1, -- 0-indexed
		cursor_col = cursor[2],
		last_line = last_line,
	}

	if overrides then
		ctx = vim.tbl_extend("force", ctx, overrides)
	end

	return ctx
end

--- Clean up all scratch buffers and reset plugin state
function M.cleanup()
	-- Delete all scratch buffers
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
		end
	end

	-- Clear relevant package.loaded entries for fresh state between test files
	for key, _ in pairs(package.loaded) do
		if key:match("^smart%-motion") then
			package.loaded[key] = nil
		end
	end
end

return M
