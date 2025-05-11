local merge = require("smart-motion.actions.utils").merge

---@type SmartMotionRegistry<SmartMotionActionModuleEntry>
local actions = require("smart-motion.core.registry")("actions")

--- @type table<string, SmartMotionActionModuleEntry>
local action_entries = {
	center = {
		run = require("smart-motion.actions.center").run,
		metadata = {
			label = "Center",
			description = "Centers the screen on the cursor using 'zz'",
		},
	},
	jump = {
		keys = { "j" },
		run = require("smart-motion.actions.jump").run,
		metadata = {
			label = "Jump",
			description = "Moves the cursor to the selected target",
		},
	},
	jump_centered = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.center"),
		}),
		metadata = {
			label = "Jump and Center",
			description = "Jumps to a target and then centers the screen",
		},
	},
	change = {
		keys = { "c" },
		run = merge({ require("smart-motion.actions.change") }),
		metadata = {
			label = "Change",
			description = "Changes text at the target and enters insert mode",
		},
	},
	change_jump = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.change"),
		}),
		metadata = {
			label = "Jump and Change",
			description = "Jumps to the target and starts a change",
		},
	},
	change_line = {
		keys = { "C" },
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.change-line"),
		}),
		metadata = {
			label = "Change Line",
			description = "Changes the entire line at the target",
		},
	},
	delete = {
		keys = { "d" },
		run = merge({ require("smart-motion.actions.delete") }),
		metadata = {
			label = "Delete",
			description = "Deletes the target text",
		},
	},
	delete_jump = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.delete"),
		}),
		metadata = {
			label = "Jump and Delete",
			description = "Jumps to the target and deletes it",
		},
	},
	delete_line = {
		keys = { "D" },
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.delete-line"),
		}),
		metadata = {
			label = "Delete Line",
			description = "Deletes the entire line at the target",
		},
	},
	yank = {
		keys = { "y" },
		run = merge({ require("smart-motion.actions.yank") }),
		metadata = {
			label = "Yank",
			description = "Yanks (copies) the selected text",
		},
	},
	yank_jump = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.yank"),
		}),
		metadata = {
			label = "Jump and Yank",
			description = "Jumps to the target and yanks it",
		},
	},
	yank_line = {
		keys = { "Y" },
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.yank-line"),
		}),
		metadata = {
			label = "Yank Line",
			description = "Yanks the entire line at the target",
		},
	},
	restore = {
		run = require("smart-motion.actions.restore").run,
		metadata = {
			label = "Restore Cursor",
			description = "Restores the cursor to its original location after a remote action",
		},
	},
	remote_delete = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.delete"),
			require("smart-motion.actions.restore"),
		}),
		metadata = {
			label = "Remote Delete",
			description = "Deletes the target without moving the cursor",
		},
	},
	remote_delete_line = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.delete-line"),
			require("smart-motion.actions.restore"),
		}),
		metadata = {
			label = "Remote Delete Line",
			description = "Deletes the line at the target without moving the cursor",
		},
	},
	remote_yank = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.yank"),
			require("smart-motion.actions.restore"),
		}),
		metadata = {
			label = "Remote Yank",
			description = "Yanks the target without moving the cursor",
		},
	},
	remote_yank_line = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.yank-line"),
			require("smart-motion.actions.restore"),
		}),
		metadata = {
			label = "Remote Yank Line",
			description = "Yanks the entire line at the target without moving the cursor",
		},
	},
}

actions.register_many(action_entries)

return actions
