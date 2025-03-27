local motions = require("smart-motion.core.registry")("motions")
local dispatcher = require("smart-motion.core.dispatcher")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")

local REQUIRED_PIPELINE_FIELDS = { "collector", "visualizer" }
local error_label = "[Motion Registry] "

function motions._validate_motion_entry(name, motion)
	local error_name = "Module '" .. name .. "': "

	if not utils.is_non_empty_string(name) then
		log.error(error_label .. error_name .. "Motion must have a non-empty name.")
		return false
	end

	if not motion.pipeline or type(motion.pipeline) ~= "table" then
		log.error(error_label .. error_name .. "Motion is missing a valid pipeline.")
		return false
	end

	return true
end

function motions.register_motion(name, motion)
	if not motions._validate_module_entry(name, motion) then
		log.error(error_label .. " Registration aborted: " .. name)
		return
	end

	motion.name = name
	motion.trigger_key = motion.trigger_key or name
	motion.metadata = motion.metadata or {}
	motion.metadata.label = motion.metadata.label or name:gsub("^%l", string.upper)
	motion.metadata.description = motion.metadata.description or ("SmartMotion: " .. motion.metadata.label)

	motions.by_name[name] = motion
	motions.by_key[motion.trigger_key] = motion

	if motion.map then
		local is_action = motion.is_action or false
		local modes = motion.modes or { "n" }
		local desc = motion.metadata.label

		for _, mode in ipairs(modes) do
			local trigger = dispatcher.trigger_motion

			if is_action then
				trigger = dispatcher.trigger_action
			end

			local handler = function()
				trigger(motion.trigger_key)
			end

			if package.loaded["which-key"] then
				local wk = require("which-key")
				wk.register({ [motion.trigger_key] = { name = desc } }, { mode = mode })
			end

			local ok, err = pcall(vim.keymap.set, mode, motion.trigger_key, handler, {
				desc = desc,
				noremap = true,
				silent = true,
			})

			if not ok then
				require("smart-motion.core.log").error(
					"Failed to register motion keymap '" .. motion.trigger_key .. "': " .. err
				)
			end
		end
	end
end

function motions.register_many_motions(tbl, opts)
	opts = opts or {}
	for name, motion in pairs(tbl) do
		if not opts.override and motions.by_name[name] then
			require("smart-motion.core.log").warn("Skipping already-registered motion: " .. name)
		else
			motions.register_motion(name, motion)
		end
	end
end

return motions
