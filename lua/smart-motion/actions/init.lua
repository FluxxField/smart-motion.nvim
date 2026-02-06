local run_motion = require("smart-motion.actions.run_motion")

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
		run = merge({ require("smart-motion.actions.change") }),
		metadata = {
			label = "Change",
			description = "Changes text at the target and enters insert mode",
		},
	},
	change_until = {
		run = merge({ require("smart-motion.actions.change") }),
		metadata = {
			label = "Change Until",
			description = "Changes from cursor up to (but not including) the target and enters insert mode",
		},
	},
	change_jump = {
		keys = { "c" },
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
			require("smart-motion.actions.change_line"),
		}),
		metadata = {
			label = "Change Line",
			description = "Changes the entire line at the target",
		},
	},
	delete = {
		run = merge({ require("smart-motion.actions.delete") }),
		metadata = {
			label = "Delete",
			description = "Deletes the target text",
		},
	},
	delete_jump = {
		keys = { "d" },
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
			require("smart-motion.actions.delete_line"),
		}),
		metadata = {
			label = "Delete Line",
			description = "Deletes the entire line at the target",
		},
	},
	yank = {
		run = merge({ require("smart-motion.actions.yank") }),
		metadata = {
			label = "Yank",
			description = "Yanks (copies) the selected text",
		},
	},
	yank_until = {
		run = merge({ require("smart-motion.actions.yank") }),
		metadata = {
			label = "Yank Until",
			description = "Yanks from cursor up to (but not including) the target",
		},
	},
	yank_jump = {
		keys = { "y" },
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
			require("smart-motion.actions.yank_line"),
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
			require("smart-motion.actions.delete_line"),
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
			require("smart-motion.actions.yank_line"),
			require("smart-motion.actions.restore"),
		}),
		metadata = {
			label = "Remote Yank Line",
			description = "Yanks the entire line at the target without moving the cursor",
		},
	},
	paste = {
		run = merge({ require("smart-motion.actions.paste") }),
		metadata = {
			label = "Paste",
			description = "Paste the selected text",
		},
	},
	paste_jump = {
		keys = { "p", "P" },
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.paste"),
		}),
		metadata = {
			label = "Jump and Paste",
			description = "Jumps to the target and paste it",
		},
	},
	paste_line = {
		run = merge({
			require("smart-motion.actions.jump"),
			require("smart-motion.actions.paste_line"),
		}),
		metadata = {
			label = "Paste Line",
			description = "Paste the entire line at the target",
		},
	},
	run_motion = run_motion,
}

actions.register_many(action_entries)

return actions
