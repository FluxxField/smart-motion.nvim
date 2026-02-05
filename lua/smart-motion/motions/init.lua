local engine = require("smart-motion.core.engine")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")

--- @type SmartMotionMotionRegistry
local motions = require("smart-motion.core.registry")("motions")

--- Fields that every motion pipeline must contain
local REQUIRED_FIELDS = { "collector", "visualizer" }

local error_label = "[Motion Registry] "

--- Validate a motion before registering it
--- @param name string
--- @param motion SmartMotionMotionEntry
--- @return boolean
function motions._validate_motion_entry(name, motion)
	local registries = require("smart-motion.core.registries"):get()
	local error_name = "Module '" .. name .. "': "

	if not utils.is_non_empty_string(name) then
		log.error(error_label .. error_name .. "Motion must have a non-empty name.")
		return false
	end

	for _, field in ipairs(REQUIRED_FIELDS) do
		local module_name = motion[field]
		if not utils.is_non_empty_string(module_name) then
			log.error("[Motion Registry] Motion '" .. name .. "' pipeline must specify '" .. field .. "'.")
			return false
		end

		local registry = registries[field .. "s"]
		if not registry.get_by_name(module_name) then
			log.error(
				"[Motion Registry] Motion '" .. name .. "' references unknown " .. field .. ": '" .. module_name .. "'"
			)
			return false
		end
	end

	return true
end

--- Register a motion with validation and keybinding logic
--- @param name string
--- @param motion SmartMotionMotionEntry
--- @param opts
function motions.register_motion(name, motion, opts)
	opts = opts or {}

	if not motions._validate_motion_entry(name, motion) then
		log.error(error_label .. " Registration aborted: " .. name)
		return
	end

	motion.name = name
	motion.trigger_key = motion.trigger_key or name
	motion.metadata = motion.metadata or {}
	motion.metadata.label = motion.metadata.label or name:gsub("^%l", string.upper)
	motion.metadata.description = motion.metadata.description or ("SmartMotion: " .. motion.metadata.label)
	motion.metadata.motion_state = motion.metadata.motion_state or {}

	motions.by_name[name] = motion
	motions.by_key[motion.trigger_key] = motion

	if motion.map then
		local infer = motion.infer or false
		local modes = motion.modes or { "n" }
		local desc = motion.metadata.label

		for _, mode in ipairs(modes) do
			local handler = function()
				if motion.count_passthrough and vim.v.count > 0 then
					local count = vim.v.count
					local cfg = require("smart-motion.config").validated
					if cfg and cfg.count_behavior == "native" then
						local keys = count .. motion.trigger_key
						vim.api.nvim_feedkeys(
							vim.api.nvim_replace_termcodes(keys, true, false, true),
							"n",
							false
						)
						return
					end
					engine.run(motion.trigger_key, { count_select = count })
					return
				end
				engine.run(motion.trigger_key)
			end

			if package.loaded["which-key"] then
				local wk = require("which-key")
				wk.add({ motion.trigger_key, desc = desc, mode = mode })
			end

			local ok, err = pcall(
				vim.keymap.set,
				mode,
				motion.trigger_key,
				handler,
				vim.tbl_deep_extend("force", {
					desc = desc,
					noremap = true,
					silent = true,
				}, opts)
			)

			if not ok then
				require("smart-motion.core.log").error(
					"Failed to register motion keymap '" .. motion.trigger_key .. "': " .. err
				)
			end
		end
	end
end

--- Register multiple motions
--- @param tbl table<string, SmartMotionMotionEntry>
--- @param opts? { override?: boolean }
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

--- Map a registered motion to its trigger key for the given modes
--- @param name string
--- @param motion_opts SmartMotionMotionEntry
--- @param opts table
function motions.map_motion(name, motion_opts, opts)
	motion_opts = motion_opts or {}
	opts = opts or {}
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.by_name[name]

	if not motion then
		log.error("Tried to map unregistered motion: " .. name)
		return
	end

	local modes = motion_opts.modes or motion.modes or { "n" }
	local desc = motion_opts.description or motion.metadata and motion.metadata.label or name
	local trigger_key = motion.trigger_key or name

	local handler = function()
		engine.run(trigger_key)
	end

	if opts.which_key ~= false and package.loaded["which-key"] then
		local wk = require("which-key")
		for _, mode in ipairs(modes) do
			wk.add({ { trigger_key, desc = desc, mode = mode } })
		end
	end

	for _, mode in ipairs(modes) do
		local ok, err = pcall(
			vim.keymap.set,
			mode,
			trigger_key,
			handler,
			vim.tbl_deep_extend("force", {
				desc = desc,
				noremap = true,
				silent = true,
			}, opts)
		)

		if not ok then
			log.error("Failed to register keymap for motion '" .. name .. "' (" .. trigger_key .. "): " .. err)
		end
	end
end

return motions
