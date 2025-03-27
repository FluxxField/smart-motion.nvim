local change = require("smart-motion.actions.change")
local delete = require("smart-motion.actions.delete")
local jump = require("smart-motion.actions.jump")
local restore = require("smart-motion.actions.restore")
local yank = require("smart-motion.actions.yank")
local action_utils = require("smart-motion.actions.utils")
local actions = require("smart-motion.core.registry")("actions")

actions.register_many({
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
	delete = {
		keys = { "d" },
		run = action_utils.merge({ jump, delete }),
		metadata = {
			label = "Delete Target",
			description = "Moves cursor to target and deletes",
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
	restore = {
		run = restore.run,
		metadata = {
			label = "Restore Cursor",
			description = "Moves Cursor back to its original position before the jump",
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
})

return actions
