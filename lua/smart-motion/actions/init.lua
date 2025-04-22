local change = require("smart-motion.actions.change")
local change_line = require("smart-motion.actions.change-line")
local delete = require("smart-motion.actions.delete")
local delete_line = require("smart-motion.actions.delete-line")
local jump = require("smart-motion.actions.jump")
local restore = require("smart-motion.actions.restore")
local yank = require("smart-motion.actions.yank")
local yank_line = require("smart-motion.actions.yank-line")
local action_utils = require("smart-motion.actions.utils")

---@type SmartMotionRegistry<SmartMotionActionModuleEntry>
local actions = require("smart-motion.core.registry")("actions")

--- @type table<string, SmartMotionActionModuleEntry>
local action_entries = {
	jump = {
		keys = { "j" },
		run = jump.run,
		metadata = {
			label = "Jump To Target",
			description = "Executes a jump to selected target hint",
		},
	},
	change = {
		keys = { "c" },
		run = action_utils.merge({ jump, change }),
		metadata = {
			label = "Change Target",
			description = "Moves cursor to target, deletes it, and puts you in insert mode",
		},
	},
	change_line = {
		keys = { "C" },
		run = action_utils.merge({ jump, change_line }),
		metadata = {
			label = "Change Line at Target",
			description = "Moves cursor to target, deletes the line, and puts you in insert mode",
		},
	},
	delete = {
		keys = { "d" },
		run = action_utils.merge({ jump, delete }),
		metadata = {
			label = "Delete Target",
			description = "Moves cursor to target and deletes",
		},
	},
	delete_line = {
		keys = { "D" },
		run = action_utils.merge({ jump, delete_line }),
		metadata = {
			label = "Delete Line at Target",
			description = "Moves cursor to target and deletes the line",
		},
	},
	yank = {
		keys = { "y" },
		run = action_utils.merge({ jump, yank }),
		metadata = {
			label = "Yank Target",
			description = "Moves cursor to target and yanks",
		},
	},
	yank_line = {
		keys = { "Y" },
		run = action_utils.merge({ jump, yank_line }),
		metadata = {
			label = "Yank Line at Target",
			description = "Moves cursor to target and yanks the line",
		},
	},
	restore = {
		run = restore.run,
		metadata = {
			label = "Restore Cursor",
			description = "Moves Cursor back to its original position before the jump",
		},
	},
	remote_delete = {
		run = action_utils.merge({
			jump,
			delete,
			restore,
		}),
		metadata = {
			label = "Remote Delete",
			description = "Executes delete on target without moving the cursor",
		},
	},
	remote_delete_line = {
		run = action_utils.merge({
			jump,
			delete_line,
			restore,
		}),
		metadata = {
			label = "Remote Delete Line at Target",
			description = "Executes delete line at target without moving the cursor",
		},
	},
	remote_yank = {
		run = action_utils.merge({
			jump,
			yank,
			restore,
		}),
		metadata = {
			label = "Remote Yank",
			description = "Executes yank on target without moving the cursor",
		},
	},
	remote_yank_line = {
		run = action_utils.merge({
			jump,
			yank_line,
			restore,
		}),
		metadata = {
			label = "Remote Yank Line at Target",
			description = "Executes yank line at target without moving the cursor",
		},
	},
}

actions.register_many(action_entries)

return actions
