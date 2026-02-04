local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects LSP diagnostics as targets.
--- Supports filtering via motion_state:
---   diagnostic_severity: vim.diagnostic.severity value (or table of values) to filter by
--- @return thread A coroutine generator yielding target-like objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr

		local diags = vim.diagnostic.get(bufnr)
		if not diags or #diags == 0 then
			log.debug("Diagnostics collector: no diagnostics in buffer " .. tostring(bufnr))
			return
		end

		-- Optional severity filter
		local severity = motion_state.diagnostic_severity
		local severity_set = nil
		if severity then
			if type(severity) == "number" then
				severity_set = { [severity] = true }
			elseif type(severity) == "table" then
				severity_set = {}
				for _, s in ipairs(severity) do
					severity_set[s] = true
				end
			end
		end

		for _, diag in ipairs(diags) do
			if severity_set and not severity_set[diag.severity] then
				goto continue
			end

			local end_lnum = diag.end_lnum or diag.lnum
			local end_col = diag.end_col or (diag.col + 1)

			coroutine.yield({
				text = diag.message,
				start_pos = { row = diag.lnum, col = diag.col },
				end_pos = { row = end_lnum, col = end_col },
				type = "diagnostic",
				metadata = {
					severity = diag.severity,
					source = diag.source,
					code = diag.code,
					message = diag.message,
				},
			})

			::continue::
		end
	end)
end

M.metadata = {
	label = "Diagnostics Collector",
	description = "Collects LSP diagnostics as jump targets",
}

return M
