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

--- Yields a single treesitter node as a target.
--- @param node TSNode
--- @param bufnr integer
--- @param extra_metadata? table
local function yield_node(node, bufnr, extra_metadata)
	local start_row, start_col, end_row, end_col = node:range()
	local text = vim.treesitter.get_node_text(node, bufnr)

	coroutine.yield({
		text = text,
		start_pos = { row = start_row, col = start_col },
		end_pos = { row = end_row, col = end_col },
		type = "treesitter",
		metadata = vim.tbl_extend("force", { node_type = node:type() }, extra_metadata or {}),
	})
end

--- Gets all named children of a node.
--- @param node TSNode
--- @return TSNode[]
local function get_named_children(node)
	local children = {}
	for child in node:iter_children() do
		if child:named() then
			table.insert(children, child)
		end
	end
	return children
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
				log.debug(
					"Failed to parse treesitter query for lang '" .. lang .. "': " .. tostring(motion_state.ts_query)
				)
				return
			end

			for id, node in query:iter_captures(root, bufnr) do
				yield_node(node, bufnr, { capture_name = query.captures[id] })
			end

			return
		end

		-- Mode 2: Yield a specific named field from matched nodes (e.g. function "name")
		if motion_state.ts_node_types and motion_state.ts_child_field then
			local nodes = {}
			walk_tree(root, motion_state.ts_node_types, nodes)

			for _, node in ipairs(nodes) do
				local field_nodes = node:field(motion_state.ts_child_field)
				for _, field_node in ipairs(field_nodes) do
					yield_node(field_node, bufnr, {
						parent_type = node:type(),
						field_name = motion_state.ts_child_field,
					})
				end
			end

			return
		end

		-- Mode 3: Yield named children of matched container nodes (e.g. arguments)
		-- When ts_around_separator is true, expands ranges to include trailing/leading separators.
		if motion_state.ts_node_types and motion_state.ts_yield_children then
			local containers = {}
			walk_tree(root, motion_state.ts_node_types, containers)

			for _, container in ipairs(containers) do
				local named_children = get_named_children(container)

				for i, child in ipairs(named_children) do
					local sr, sc, er, ec = child:range()

					-- Expand range to include separators (commas, whitespace) for "around" semantics
					if motion_state.ts_around_separator and #named_children > 1 then
						local is_last = (i == #named_children)
						if not is_last then
							-- Include trailing separator: extend end to start of next named child
							local next_child = named_children[i + 1]
							local nsr, nsc = next_child:range()
							er = nsr
							ec = nsc
						else
							-- Last child: include leading separator from end of previous named child
							local prev_child = named_children[i - 1]
							local _, _, per, pec = prev_child:range()
							sr = per
							sc = pec
						end
					end

					local text = vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})

					coroutine.yield({
						text = table.concat(text, "\n"),
						start_pos = { row = sr, col = sc },
						end_pos = { row = er, col = ec },
						type = "treesitter",
						metadata = {
							node_type = child:type(),
							parent_type = container:type(),
							child_index = i,
							child_count = #named_children,
						},
					})
				end
			end

			return
		end

		-- Mode 4: Plain node type matching (language-agnostic)
		if motion_state.ts_node_types then
			local nodes = {}
			walk_tree(root, motion_state.ts_node_types, nodes)

			for _, node in ipairs(nodes) do
				yield_node(node, bufnr)
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
