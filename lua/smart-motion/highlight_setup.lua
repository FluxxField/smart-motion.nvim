local log = require("smart-motion.core.log")

--- @alias HighlightDefinition string | { fg?: string, bg?: string, bold?: boolean, italic?: boolean, underline?: boolean }

--- @type table<string, { fg: string, bg: string }>
local default_highlights = {
	SmartMotionHint = { fg = "#E06C75", bg = "none" },
	SmartMotionHintDim = { fg = "#7F4A4A", bg = "none" },
	SmartMotionFirstChar = { fg = "#98C379", bg = "none" },
	SmartMotionFirstCharDim = { fg = "#6F8D57", bg = "none" },
	SmartMotionSecondChar = { fg = "#61AFEF", bg = "none" },
	SmartMotionSecondCharDim = { fg = "#3E5E76", bg = "none" },
	SmartMotionDim = { fg = "#5C6370", bg = "none" },
	SmartMotionSearchPrefix = { fg = "#FFFFFF", bg = "none" },
	SmartMotionSearchPrefixDim = { fg = "#CCCCCC", bg = "none" }, -- optional for dimmed during search
}

local M = {}

--- Helper: Convert "first_char" to "SmartMotionFirstChar"
local function highlight_key_to_group(key)
	return "SmartMotion" .. key:gsub("_(%l)", string.upper)
end

---@param group string
---@param opts { fg?: string, bg?: string, [string]: any }
local function apply_highlight(group, opts)
	vim.api.nvim_set_hl(0, group, opts)
end

--- Ensure all default highlight groups exist.
local function apply_default_highlights()
	for group, opts in pairs(default_highlights) do
		apply_highlight(group, opts)
	end
end

--- Sets up highlights for SmartMotion.
---@param cfg table Validated user config.
function M.setup(cfg)
	log.debug("Setting up SmartMotion highlights")

	-- Always apply defaults first to ensure they exist.
	apply_default_highlights()

	local highlight_config = cfg.highlight or {}

	-- Process each user-defined highlight.
	for key, value in pairs(highlight_config) do
		local default_group = highlight_key_to_group(key)

		if type(value) == "table" then
			-- User gave colors directly — override everything.
			apply_highlight(default_group, value)
		elseif type(value) == "string" then
			-- User referenced an external/custom group.
			local ok = pcall(vim.api.nvim_get_hl_by_name, value, true)

			if ok then
				-- If it exists, we're good.
				cfg.highlight[key] = value
			else
				-- If it does not exist, fallback to the default group.
				log.debug(
					"Custom highlight group '"
						.. value
						.. "' not found, falling back to default '"
						.. default_group
						.. "'"
				)
				cfg.highlight[key] = default_group
			end
		else
			log.error("Invalid highlight type for '" .. key .. "': expected string or table, got " .. type(value))
			error("Invalid highlight type for '" .. key .. "'")
		end
	end

	log.debug("SmartMotion highlights applied successfully.")

	-- Reapply highlights after ColorScheme changes.
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("SmartMotionHighlights", { clear = true }),
		callback = function()
			local reloaded_cfg = require("smart-motion.config").validated
			if reloaded_cfg then
				M.setup(reloaded_cfg)
			end
		end,
	})
end

return M
