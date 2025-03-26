local create_registry = require("smart-motion.core.registry")
local dispatcher = require("smart-motion.core.dispatcher")

local motions = create_registry()

function motions.register_motion(name, motion)
	motion.trigger_key = motion.trigger_key or name
	motion.metadata = motion.metadata or {}
	motion.metadata.label = motion.metadata.label or name:gsub("^%l", string.upper)
	motion.metadata.description = motion.metadata.description or ("SmartMotion: " .. motion.metadata.label)

	motions.by_name[name] = motion
	motions.by_key[motion.trigger_key] = motion

	if motion.map then
		local modes = motion.modes or { "n" }
		local desc = motion.metadata.label

		for _, mode in ipairs(modes) do
			local handler = function()
				dispatcher.trigger_motion(motion.trigger_key)
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
