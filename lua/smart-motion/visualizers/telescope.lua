local exit = require("smart-motion.core.events.exit")
local highlight = require("smart-motion.core.highlight")
local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionVisualizerModuleEntry
local M = {}

--- Open Telescope picker with targets for fuzzy selection
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	-- Check if Telescope is available and trigger lazy loading if needed
	local ok = pcall(require, "telescope")

	if not ok then
		-- Try lazy.nvim's require function which handles lazy loading
		local has_lazy, lazy = pcall(require, "lazy")
		if has_lazy then
			-- This should trigger lazy loading
			pcall(function()
				lazy.load({ plugins = { "telescope.nvim" } })
			end)
			ok = pcall(require, "telescope")
		end
	end

	if not ok then
		vim.notify("SmartMotion: Telescope not available, falling back to quickfix", vim.log.levels.WARN)
		require("smart-motion.visualizers.quickfix").run(ctx, cfg, motion_state)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	local targets = motion_state.jump_targets or {}

	if #targets == 0 then
		exit.throw(EXIT_TYPE.EARLY_EXIT)
		return
	end

	-- Clear any existing highlights before opening Telescope
	highlight.clear(ctx, cfg, motion_state)

	-- Build title
	local title = "SmartMotion Targets"
	if motion_state.motion and motion_state.motion.trigger_key then
		title = title .. " [" .. motion_state.motion.trigger_key .. "]"
	end

	-- Store references for the async callback
	local stored_ctx = ctx
	local stored_cfg = cfg
	local stored_motion_state = motion_state

	pickers
		.new({}, {
			prompt_title = title,
			finder = finders.new_table({
				results = targets,
				entry_maker = function(target)
					local bufnr = target.metadata and target.metadata.bufnr or ctx.bufnr
					local filename = vim.api.nvim_buf_get_name(bufnr)
					local short_filename = vim.fn.fnamemodify(filename, ":t")
					local lnum = target.start_pos.row + 1
					local col = target.start_pos.col + 1

					-- Get display text: prefer target.text, fall back to line content
					local display_text = target.text
					if not display_text or display_text == "" then
						local lines =
							vim.api.nvim_buf_get_lines(bufnr, target.start_pos.row, target.start_pos.row + 1, false)
						display_text = lines and lines[1] and vim.trim(lines[1]) or ""
					end

					-- Format: filename:line:col  text
					local display = string.format("%s:%d:%d  %s", short_filename, lnum, col, display_text)

					return {
						value = target,
						display = display,
						ordinal = display_text .. " " .. filename,
						filename = filename,
						lnum = lnum,
						col = col,
						bufnr = bufnr,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = previewers.new_buffer_previewer({
				title = "Preview",
				define_preview = function(self, entry, status)
					-- Load the buffer content into the preview
					local bufnr = entry.bufnr
					local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

					-- Set filetype for syntax highlighting
					local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
					if ft and ft ~= "" then
						vim.api.nvim_set_option_value("filetype", ft, { buf = self.state.bufnr })
					end

					-- Highlight the target line
					local hl_line = entry.lnum - 1
					if hl_line >= 0 and hl_line < #lines then
						vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, "TelescopePreviewLine", hl_line, 0, -1)
					end

					-- Scroll to show the target line (centered)
					vim.schedule(function()
						if self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
							local win_height = vim.api.nvim_win_get_height(self.state.winid)
							local scroll_line = math.max(0, entry.lnum - math.floor(win_height / 2))
							vim.api.nvim_win_set_cursor(self.state.winid, { entry.lnum, entry.col - 1 })
							pcall(vim.api.nvim_win_call, self.state.winid, function()
								vim.cmd("normal! zz")
							end)
						end
					end)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if selection then
						stored_motion_state.selected_jump_target = selection.value

						-- Run the action directly (we're outside the normal pipeline flow)
						local module_loader = require("smart-motion.utils.module_loader")
						local modules = module_loader.get_modules(
							stored_ctx,
							stored_cfg,
							stored_motion_state,
							{ "action" }
						)

						-- Check if we should use jump action (for operator-pending mode)
						if stored_ctx.mode and stored_ctx.mode:find("o") then
							require("smart-motion.actions.jump").run(
								stored_ctx,
								stored_cfg,
								stored_motion_state
							)
						else
							modules.action.run(stored_ctx, stored_cfg, stored_motion_state)
						end
					end
				end)
				return true
			end,
		})
		:find()

	-- Exit early - Telescope handles everything asynchronously
	exit.throw(EXIT_TYPE.EARLY_EXIT)
end

M.metadata = {
	label = "Telescope Visualizer",
	description = "Opens Telescope picker for fuzzy finding targets",
	motion_state = {
		dim_background = false,
	},
}

return M
