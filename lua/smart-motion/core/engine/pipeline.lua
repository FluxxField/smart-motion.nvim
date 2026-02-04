local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local module_loader = require("smart-motion.utils.module_loader")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

--- Creates a multi-window collector that runs the base collector for each visible window.
--- @param collector table The collector module
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @return thread A coroutine generator yielding items from all windows
local function create_multi_window_collector(collector, ctx, cfg, motion_state)
	return coroutine.create(function(ctx_arg, cfg_arg, motion_state_arg)
		for _, win in ipairs(ctx_arg.windows) do
			local sub_ctx = vim.tbl_extend("force", ctx_arg, {
				bufnr = win.bufnr,
				winid = win.winid,
				cursor_line = win.cursor_line,
				cursor_col = win.cursor_col,
				last_line = win.last_line,
			})

			local gen = collector.run()
			if not gen then
				goto continue
			end

			-- First resume passes context to the collector coroutine
			local ok, item = exit.safe(coroutine.resume(gen, sub_ctx, cfg_arg, motion_state_arg))
			if not ok then
				goto continue
			end

			while item do
				-- Inject per-window metadata so targets know which window they came from
				item.metadata = item.metadata or {}
				item.metadata.bufnr = win.bufnr
				item.metadata.winid = win.winid

				coroutine.yield(item)

				ok, item = exit.safe(coroutine.resume(gen, sub_ctx, cfg_arg, motion_state_arg))
				if not ok then
					break
				end
			end

			::continue::
		end
	end)
end

--- Prepares the pipeline by collecting and extracting motion targets.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local modules =
		module_loader.get_modules(ctx, cfg, motion_state, { "collector", "extractor", "modifier", "filter" })

	local collector_generator
	if motion_state.multi_window and ctx.windows and #ctx.windows > 1
		and not (ctx.mode and ctx.mode:find("o")) then
		collector_generator = create_multi_window_collector(modules.collector, ctx, cfg, motion_state)
	else
		collector_generator = modules.collector.run()
	end
	exit.throw_if(not collector_generator, EXIT_TYPE.EARLY_EXIT)

	local extractor_generator = modules.extractor.run(collector_generator)
	exit.throw_if(not extractor_generator, EXIT_TYPE.EARLY_EXIT)

	local modifier_generator = modules.modifier.run(extractor_generator)
	exit.throw_if(not modifier_generator, EXIT_TYPE.EARLY_EXIT)

	local filter_generator = modules.filter.run(modifier_generator)
	exit.throw_if(not filter_generator)

	targets.get_targets(ctx, cfg, motion_state, filter_generator)
	state.finalize_motion_state(ctx, cfg, motion_state)
end

return M
