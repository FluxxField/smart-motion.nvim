local change = require("smart-motion.actions.change")
local change_line = require("smart-motion.actions.change-line")
local delete = require("smart-motion.actions.delete")
local delete_line = require("smart-motion.actions.delete-line")
local jump = require("smart-motion.actions.jump")
local restore = require("smart-motion.actions.restore")
local yank = require("smart-motion.actions.yank")
local yank_line = require("smart-motion.actions.yank-line")
local action_utils = require("smart-motion.actions.utils")
local until_action = require("smart-motion.actions.until")

---@type SmartMotionRegistry<SmartMotionActionModuleEntry>
local actions = require("smart-motion.core.registry")("actions")

--- @type table<string, SmartMotionActionModuleEntry>
local action_entries = {
	jump = {
		keys = { "j" },
		run = jump.run,
	},
	change = {
		keys = { "c" },
		run = action_utils.merge({ change }),
	},
	change_jump = {
		run = action_utils.merge({ jump, change }),
	},
	change_line = {
		keys = { "C" },
		run = action_utils.merge({ jump, change_line }),
	},
	change_until = {
		run = action_utils.merge({ until_action, change }),
	},
	delete = {
		keys = { "d" },
		run = action_utils.merge({ delete }),
	},
	delete_jump = {
		run = action_utils.merge({ jump, delete }),
	},
	delete_line = {
		keys = { "D" },
		run = action_utils.merge({ jump, delete_line }),
	},
	delete_until = {
		run = action_utils.merge({ until_action, delete }),
	},
	yank = {
		keys = { "y" },
		run = action_utils.merge({ yank }),
	},
	yank_jump = {
		run = action_utils.merge({ jump, yank }),
	},
	yank_line = {
		keys = { "Y" },
		run = action_utils.merge({ jump, yank_line }),
	},
	yank_until = {
		run = action_utils.merge({ until_action, yank }),
	},
	restore = {
		run = restore.run,
	},
	remote_delete = {
		run = action_utils.merge({
			jump,
			delete,
			restore,
		}),
	},
	remote_delete_line = {
		run = action_utils.merge({
			jump,
			delete_line,
			restore,
		}),
	},
	remote_yank = {
		run = action_utils.merge({
			jump,
			yank,
			restore,
		}),
	},
	remote_yank_line = {
		run = action_utils.merge({
			jump,
			yank_line,
			restore,
		}),
	},
}

actions.register_many(action_entries)

return actions
