local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Recursively walks a treesitter node tree and collects nodes matching the given types.
--- @param node TSNode
--- @param node_types string[]
--- @param results TSNode[]
local function walk_tree(node, node_types, results)
	if vim.tbl_contains(node_types, node:type()) then
		table.insert(results, node)
	end

	for child in node:iter_children() do
		walk_tree(child, node_types, results)
	end
end

--- Collects treesitter nodes as targets.
--- Supports two modes via motion_state:
---   ts_query: raw treesitter query string (language-specific)
---   ts_node_types: list of node type strings to match by walking the tree
--- @return thread A coroutine generator yielding target-like objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr

		local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
		if not ok or not parser then
			log.debug("Treesitter parser not available for buffer " .. tostring(bufnr))
			return
		end

		local trees = parser:parse()
		if not trees or not trees[1] then
			log.debug("Treesitter failed to parse buffer")
			return
		end

		local root = trees[1]:root()
		local lang = parser:lang()

		-- Mode 1: Raw treesitter query
		if motion_state.ts_query then
			local query_ok, query = pcall(vim.treesitter.query.parse, lang, motion_state.ts_query)
			if not query_ok or not query then
				log.debug("Failed to parse treesitter query for lang '" .. lang .. "': " .. tostring(motion_state.ts_query))
				return
			end

			for id, node in query:iter_captures(root, bufnr) do
				local start_row, start_col, end_row, end_col = node:range()
				local text = vim.treesitter.get_node_text(node, bufnr)

				coroutine.yield({
					text = text,
					start_pos = { row = start_row, col = start_col },
					end_pos = { row = end_row, col = end_col },
					type = "treesitter",
					metadata = {
						node_type = node:type(),
						capture_name = query.captures[id],
					},
				})
			end

			return
		end

		-- Mode 2: Node type matching (language-agnostic)
		if motion_state.ts_node_types then
			local nodes = {}
			walk_tree(root, motion_state.ts_node_types, nodes)

			for _, node in ipairs(nodes) do
				local start_row, start_col, end_row, end_col = node:range()
				local text = vim.treesitter.get_node_text(node, bufnr)

				coroutine.yield({
					text = text,
					start_pos = { row = start_row, col = start_col },
					end_pos = { row = end_row, col = end_col },
					type = "treesitter",
					metadata = {
						node_type = node:type(),
					},
				})
			end

			return
		end

		log.debug("Treesitter collector: no ts_query or ts_node_types specified in motion_state")
	end)
end

M.metadata = {
	label = "Treesitter Collector",
	description = "Collects targets from treesitter nodes matching a query or node types",
}

return M
