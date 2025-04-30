local M = {}

--- Detect if `nvim-notify` is available.
---@return boolean
local function has_notify()
	return package.loaded["notify"] ~= nil
end

--- Internal wrapper to handle actual logging.
---@param msg string
---@param level integer
---@param opts table|nil
local function log(msg, level, opts)
	-- if has_notify() then
	-- 	require("notify")(msg, level, opts or {})
	-- else
	vim.notify(msg, level)
	-- end
end

--- Logs an error message.
---@param msg string
function M.error(msg)
	log("smart-motion: " .. msg, vim.log.levels.ERROR)
end

--- Logs a warning message.
---@param msg string
function M.warn(msg)
	log("smart-motion: " .. msg, vim.log.levels.WARN)
end

--- Logs an info message.
---@param msg string
function M.info(msg)
	log("smart-motion: " .. msg, vim.log.levels.INFO)
end

--- Logs a debug message, hidden behind a debug flag.
---@param msg string
function M.debug(msg)
	if not vim.g.smartmotion_debug then
		return
	end

	log("smart-motion [DEBUG]: " .. msg, vim.log.levels.DEBUG)
end

return M
