--- Argument swap via dual label picks.
--- Triggered by `saa`: pick two arguments, swap their text.
local M = {}

-- Same container types used by daa/caa/yaa
local arg_container_types = {
	"arguments",
	"argument_list",
	"parameters",
	"parameter_list",
	"formal_parameters",
}

--- Collects treesitter argument children from the current buffer.
---@param ctx SmartMotionContext
---@return table[]
function M._collect_ts_targets(ctx)
	local log = require("smart-motion.core.log")
	local targets = {}
	local bufnr = ctx.bufnr

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		log.debug("Treesitter parser not available for buffer " .. tostring(bufnr))
		return targets
	end

	local trees = parser:parse()
	if not trees or not trees[1] then
		return targets
	end

	local root = trees[1]:root()

	-- Walk tree to find argument containers
	local containers = {}
	local function walk_tree(node)
		if vim.tbl_contains(arg_container_types, node:type()) then
			table.insert(containers, node)
		end
		for child in node:iter_children() do
			walk_tree(child)
		end
	end
	walk_tree(root)

	-- Yield named children of each container (individual arguments)
	for _, container in ipairs(containers) do
		for child in container:iter_children() do
			if child:named() then
				local sr, sc, er, ec = child:range()
				local text = vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})

				table.insert(targets, {
					text = table.concat(text, "\n"),
					start_pos = { row = sr, col = sc },
					end_pos = { row = er, col = ec },
					type = "treesitter",
					metadata = {
						bufnr = bufnr,
						winid = ctx.winid,
						node_type = child:type(),
						parent_type = container:type(),
					},
				})
			end
		end
	end

	return targets
end

--- Runs argument swap: pick two arguments, swap their text.
function M.run()
	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight = require("smart-motion.core.highlight")
	local dual_selection = require("smart-motion.core.dual_selection")
	local cfg_mod = require("smart-motion.config")

	local cfg = cfg_mod.validated
	if not cfg then
		return
	end

	local ctx = context.get()
	local motion_state = state.create_motion_state()

	local targets = M._collect_ts_targets(ctx)
	if #targets < 2 then
		return
	end

	motion_state.jump_targets = targets
	state.finalize_motion_state(ctx, cfg, motion_state)

	local first, second = dual_selection.run(ctx, cfg, motion_state)

	if not first or not second then
		highlight.clear(ctx, cfg, motion_state)
		vim.cmd("redraw")
		return
	end

	-- Read text from both targets
	local first_text = vim.api.nvim_buf_get_text(
		ctx.bufnr, first.start_pos.row, first.start_pos.col,
		first.end_pos.row, first.end_pos.col, {})
	local second_text = vim.api.nvim_buf_get_text(
		ctx.bufnr, second.start_pos.row, second.start_pos.col,
		second.end_pos.row, second.end_pos.col, {})

	-- Order: a is earlier, b is later (replace later first for position stability)
	local a, b = first, second
	local a_text, b_text = first_text, second_text
	if a.start_pos.row > b.start_pos.row
		or (a.start_pos.row == b.start_pos.row and a.start_pos.col > b.start_pos.col) then
		a, b = b, a
		a_text, b_text = b_text, a_text
	end

	-- Replace b (later position) with a's text, then a (earlier position) with b's text
	vim.api.nvim_buf_set_text(ctx.bufnr,
		b.start_pos.row, b.start_pos.col, b.end_pos.row, b.end_pos.col, a_text)
	vim.api.nvim_buf_set_text(ctx.bufnr,
		a.start_pos.row, a.start_pos.col, a.end_pos.row, a.end_pos.col, b_text)
end

return M
