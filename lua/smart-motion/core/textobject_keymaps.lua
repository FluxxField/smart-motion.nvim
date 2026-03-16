local log = require("smart-motion.core.log")

local M = {}

local registered = false

--- Register i and a keymaps in visual and operator-pending modes.
--- These keymaps read the next char, look up the textobject registry,
--- and run the smart-motion pipeline if a textobject is found.
--- If not found, falls back to native vim text object behavior.
---
--- Only registers once — safe to call multiple times.
function M.setup()
	if registered then
		return
	end
	registered = true

	for _, prefix in ipairs({ "i", "a" }) do
		local textobject_key = prefix == "i" and "inside" or "around"

		vim.keymap.set({ "x", "o" }, prefix, function()
			local ok, raw = pcall(vim.fn.getchar)
			if not ok then
				return
			end
			local char = type(raw) == "number" and vim.fn.nr2char(raw) or raw
			if char == "\027" then
				return
			end -- ESC

			local motions_reg = require("smart-motion.motions")
			local textobject = motions_reg.get_textobject(char)

			if textobject then
				require("smart-motion.core.engine").run_textobject(textobject, textobject_key)
			else
				-- Not a registered textobject — feed back to vim for native handling.
				-- Use noremap so we don't recurse into this handler.
				local keys = vim.api.nvim_replace_termcodes(prefix .. char, true, false, true)
				vim.api.nvim_feedkeys(keys, "n", false)
			end
		end, {
			desc = "Smart-motion " .. textobject_key .. " text object",
			noremap = true,
			silent = true,
		})
	end
end

return M
