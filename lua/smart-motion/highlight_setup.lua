local log = require("smart-motion.core.log")

--- @alias HighlightDefinition string | { fg?: string, bg?: string, bold?: boolean, italic?: boolean, underline?: boolean }

--- @type table<string, { fg: string, bg: string }>
local default_highlights = {
	SmartMotionHint = { fg = "#FF2FD0", bg = "none" },
	SmartMotionHintDim = { fg = "#C05AA0", bg = "none" },
	SmartMotionTwoCharHint = { fg = "#2FD0FF", bg = "none" },
	SmartMotionTwoCharHintDim = { fg = "#2F80A0", bg = "none" },
	SmartMotionDim = { fg = "#555555", bg = "none" },
	SmartMotionSearchPrefix = { fg = "#BBBBBB", bg = "none" },
	SmartMotionSearchPrefixDim = { fg = "#888888", bg = "none" },
}

local background_highlights = {
	SmartMotionHint = { fg = "#FAFAFA", bg = "#FF2FD0", bold = true },
	SmartMotionHintDim = { fg = "#C05AA0", bg = "none" },
	SmartMotionTwoCharHint = { fg = "#FAFAFA", bg = "#2FD0FF", bold = true },
	SmartMotionTwoCharHintDim = { fg = "#2F80A0", bg = "none" },
	SmartMotionDim = { fg = "#555555", bg = "none" },
	SmartMotionSearchPrefix = { fg = "#E0E0E0", bg = "#333333" },
	SmartMotionSearchPrefixDim = { fg = "#AAAAAA", bg = "#1F1F1F" },
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
local function apply_highlights(cfg)
	local highlights = default_highlights

	if cfg.use_background_highlights then
		highlights = background_highlights
	end

	for group, opts in pairs(highlights) do
		apply_highlight(group, opts)
	end
end

--- Sets up highlights for SmartMotion.
---@param cfg table Validated user config.
function M.setup(cfg)
	log.debug("Setting up SmartMotion highlights")

	-- Always apply defaults first to ensure they exist.
	apply_highlights(cfg)

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
