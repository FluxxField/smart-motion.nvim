--- Treesitter incremental selection.
--- Triggered by a keymap: select smallest node at cursor, use ; to expand, , to shrink.
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local M = {}

-- State during incremental selection
M._active = false
M._node_stack = {} -- Stack of nodes: [1] = smallest, [n] = largest visited
M._current_index = 0 -- Index into node_stack for current selection
M._bufnr = nil
M._initial_mode = nil

--- Gets the smallest named node at the cursor position.
---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return TSNode|nil
local function get_node_at_cursor(bufnr, row, col)
	local ok, node = pcall(vim.treesitter.get_node, {
		bufnr = bufnr,
		pos = { row, col },
	})
	if not ok or not node then
		return nil
	end
	-- Get the smallest named node
	while node and not node:named() do
		node = node:parent()
	end
	return node
end

--- Builds the node stack from smallest to root, skipping nodes with duplicate ranges.
---@param node TSNode
---@return TSNode[]
local function build_node_stack(node)
	local stack = {}
	local current = node
	local last_range = nil

	while current do
		if current:named() then
			local sr, sc, er, ec = current:range()
			local range_key = string.format("%d:%d-%d:%d", sr, sc, er, ec)

			-- Only add if range is different from previous node
			if range_key ~= last_range then
				table.insert(stack, current)
				last_range = range_key
			end
		end
		current = current:parent()
	end
	return stack
end

--- Selects the range of a node in visual mode.
---@param node TSNode
---@param bufnr integer
local function select_node(node, bufnr)
	local sr, sc, er, ec = node:range()

	-- Exit any existing visual mode first
	local mode = vim.fn.mode()
	if mode:find("[vV]") or mode == "\22" then
		vim.cmd("normal! v")
	end

	-- Move cursor to start of node
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })

	-- Enter visual mode
	vim.cmd("normal! v")

	-- Extend to end of node (ec is exclusive, so -1 for inclusive end)
	-- Handle case where node ends at start of next line
	if ec == 0 and er > sr then
		-- Node ends at column 0 of er, so select to end of er-1
		local prev_line = vim.api.nvim_buf_get_lines(bufnr, er - 1, er, false)[1]
		vim.api.nvim_win_set_cursor(0, { er, math.max(#prev_line - 1, 0) })
	else
		vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
	end
end

--- Shows node type in echo area.
---@param node TSNode
---@param index integer
---@param total integer
local function show_node_info(node, index, total)
	local node_type = node:type()
	vim.api.nvim_echo({
		{ "Treesitter: ", "Comment" },
		{ node_type, "Type" },
		{ string.format(" [%d/%d]", index, total), "Comment" },
		{ " (; expand, , shrink, Enter confirm, Esc cancel)", "Comment" },
	}, false, {})
end

--- Cleans up state and exits incremental selection.
local function cleanup()
	M._active = false
	M._node_stack = {}
	M._current_index = 0
	M._bufnr = nil
	M._initial_mode = nil
	-- Clear any temporary keymaps
	pcall(vim.keymap.del, "x", ";", { buffer = M._bufnr })
	pcall(vim.keymap.del, "x", ",", { buffer = M._bufnr })
	pcall(vim.keymap.del, "x", "<CR>", { buffer = M._bufnr })
	pcall(vim.keymap.del, "x", "<Esc>", { buffer = M._bufnr })
	vim.api.nvim_echo({ { "", "" } }, false, {})
end

--- Expands selection to parent node.
function M.expand()
	if not M._active or #M._node_stack == 0 then
		return
	end

	if M._current_index < #M._node_stack then
		M._current_index = M._current_index + 1
		local node = M._node_stack[M._current_index]
		select_node(node, M._bufnr)
		show_node_info(node, M._current_index, #M._node_stack)
	end
end

--- Shrinks selection to child node.
function M.shrink()
	if not M._active or #M._node_stack == 0 then
		return
	end

	if M._current_index > 1 then
		M._current_index = M._current_index - 1
		local node = M._node_stack[M._current_index]
		select_node(node, M._bufnr)
		show_node_info(node, M._current_index, #M._node_stack)
	end
end

--- Confirms selection and exits.
function M.confirm()
	if not M._active then
		return
	end
	-- Keep visual selection, just clean up state
	local bufnr = M._bufnr
	M._active = false
	M._node_stack = {}
	M._current_index = 0
	M._bufnr = nil
	M._initial_mode = nil
	-- Remove keymaps
	pcall(vim.keymap.del, "x", ";", { buffer = bufnr })
	pcall(vim.keymap.del, "x", ",", { buffer = bufnr })
	pcall(vim.keymap.del, "x", "<CR>", { buffer = bufnr })
	pcall(vim.keymap.del, "x", "<Esc>", { buffer = bufnr })
	vim.api.nvim_echo({ { "", "" } }, false, {})
end

--- Cancels selection and exits.
function M.cancel()
	if not M._active then
		return
	end
	local bufnr = M._bufnr
	cleanup()
	-- Exit visual mode
	vim.cmd("normal! v")
	vim.api.nvim_echo({ { "", "" } }, false, {})
end

--- Starts treesitter incremental selection at cursor.
function M.run()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local col = cursor[2]

	-- Check if treesitter is available
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		vim.notify("Treesitter not available for this buffer", vim.log.levels.WARN)
		return
	end

	-- Parse to ensure tree is up to date
	parser:parse()

	-- Get node at cursor
	local node = get_node_at_cursor(bufnr, row, col)
	if not node then
		vim.notify("No treesitter node at cursor", vim.log.levels.WARN)
		return
	end

	-- Build stack from smallest to root
	local stack = build_node_stack(node)
	if #stack == 0 then
		vim.notify("No named treesitter nodes found", vim.log.levels.WARN)
		return
	end

	-- Initialize state
	M._active = true
	M._node_stack = stack
	M._current_index = 1
	M._bufnr = bufnr
	M._initial_mode = vim.fn.mode()

	-- Select the smallest node
	select_node(stack[1], bufnr)
	show_node_info(stack[1], 1, #stack)

	-- Set up temporary keymaps for visual mode
	vim.keymap.set("x", ";", function()
		M.expand()
	end, { buffer = bufnr, nowait = true, desc = "Expand TS selection" })

	vim.keymap.set("x", ",", function()
		M.shrink()
	end, { buffer = bufnr, nowait = true, desc = "Shrink TS selection" })

	vim.keymap.set("x", "<CR>", function()
		M.confirm()
	end, { buffer = bufnr, nowait = true, desc = "Confirm TS selection" })

	vim.keymap.set("x", "<Esc>", function()
		M.cancel()
	end, { buffer = bufnr, nowait = true, desc = "Cancel TS selection" })
end

return M
