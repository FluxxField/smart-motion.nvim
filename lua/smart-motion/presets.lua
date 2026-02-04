local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionPresetsModule
local presets = {}

--- @param exclude? SmartMotionPresetKey.Words[]
function presets.words(exclude)
	presets._register({
		w = {
			collector = "lines",
			extractor = "words",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			metadata = {
				label = "Jump to Start of Word after cursor",
				description = "Jumps to the start of a visible word target using labels after the cursor",
			},
		},
		b = {
			collector = "lines",
			extractor = "words",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			metadata = {
				label = "Jump to Start of Word before cursor",
				description = "Jumps to the start of a visible word target using labels before the cursor",
			},
		},
		e = {
			collector = "lines",
			extractor = "words",
			filter = "filter_words_after_cursor",
			visualizer = "hint_end",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			metadata = {
				label = "Jump to End of Word after cursor",
				description = "Jumps to the end of a visible word target using labels after the cursor",
			},
		},
		ge = {
			collector = "lines",
			extractor = "words",
			filter = "filter_words_before_cursor",
			visualizer = "hint_end",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			metadata = {
				label = "Jump to End of Word before cursor",
				description = "Jumps to the end of a visible word target using labels before the cursor",
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Lines[]
function presets.lines(exclude)
	presets._register({
		j = {
			collector = "lines",
			extractor = "lines",
			filter = "filter_lines_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			metadata = {
				label = "Jump to Line after cursor",
				description = "Jumps to the start of the line after the cursor",
			},
		},
		k = {
			collector = "lines",
			extractor = "lines",
			filter = "filter_lines_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			metadata = {
				label = "Jump to Line before cursor",
				description = "Jumps to the start of the line before the cursor",
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Search[]
function presets.search(exclude)
	presets._register({
		s = {
			collector = "lines",
			extractor = "live_search",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Live Search",
				description = "Live search across all visible text with labeled results",
				motion_state = {
					multi_window = true,
				},
			},
		},
		f = {
			collector = "lines",
			extractor = "text_search_2_char",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "2 Character Find After Cursor",
				description = "Labels 2 Character Searches and jump to target",
				motion_state = {
					multi_window = true,
				},
			},
		},
		F = {
			collector = "lines",
			extractor = "text_search_2_char",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "2 Character Find Before Cursor",
				description = "Labels 2 Character Searches and jump to target",
				motion_state = {
					multi_window = true,
				},
			},
		},
		t = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Till Character After Cursor",
				description = "Jump to just before the searched character after cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
		T = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Till Character Before Cursor",
				description = "Jump to just after the searched character before cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
	}, exclude)

	-- Register ;/, keymaps for repeating last f/F/t/T
	local char_repeat = require("smart-motion.search.char_repeat")

	vim.keymap.set({ "n", "v" }, ";", function()
		char_repeat.run(false)
	end, { desc = "Repeat last char motion", noremap = true, silent = true })

	vim.keymap.set({ "n", "v" }, ",", function()
		char_repeat.run(true)
	end, { desc = "Repeat last char motion (reversed)", noremap = true, silent = true })

	-- Register gs keymap for visual range selection
	if not (type(exclude) == "table" and exclude["gs"] == false) then
		vim.keymap.set("n", "gs", function()
			require("smart-motion.actions.visual_select").run()
		end, { desc = "Visual select via labels", noremap = true, silent = true })
	end
end

--- @param exclude? SmartMotionPresetKey.Delete[]
function presets.delete(exclude)
	presets._register({
		d = {
			infer = true,
			collector = "lines",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Action",
				description = "Deletes based on motion provided",
				motion_state = {
					allow_quick_action = true,
				},
			},
		},
		dt = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_on_cursor_line_after_cursor",
			visualizer = "hint_start",
			action = "delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Until Searched Text After Cursor",
				description = "Deletes until the searched for text after the cursor",
			},
		},
		dT = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_on_cursor_line_before_cursor",
			visualizer = "hint_start",
			action = "delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Until Searched Text Before Cursor",
				description = "Deletes until the searched for text before the cursor",
			},
		},
		rdw = {
			collector = "lines",
			extractor = "words",
			modifier = "weight_distance",
			filter = "filter_lines_around_cursor",
			visualizer = "hint_start",
			action = "remote_delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Delete Word",
				description = "Deletes the selected word without moving the cursor",
			},
		},
		rdl = {
			collector = "lines",
			extractor = "lines",
			modifier = "weight_distance",
			filter = "filter_lines_around_cursor",
			visualizer = "hint_start",
			action = "remote_delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Delete Line",
				description = "Deletes the selected line without moving the cursor",
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Yank[]
function presets.yank(exclude)
	presets._register({
		y = {
			infer = true,
			collector = "lines",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Action",
				description = "Yanks based on the motion provided",
				motion_state = {
					allow_quick_action = true,
				},
			},
		},
		yt = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_on_cursor_line_after_cursor",
			visualizer = "hint_start",
			action = "yank_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Until Searched Text After Cursor",
				description = "Yank until the searched for text after the cursor",
			},
		},
		yT = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_on_cursor_line_before_cursor",
			visualizer = "hint_start",
			action = "yank_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Until Searched Text Before Cursor",
				description = "Yank until the searched for text before the cursor",
			},
		},
		ryw = {
			collector = "lines",
			extractor = "words",
			modifier = "weight_distance",
			filter = "filter_lines_around_cursor",
			visualizer = "hint_start",
			action = "remote_yank",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Yank Word",
				description = "Yanks the selected word without moving the cursor",
			},
		},
		ryl = {
			collector = "lines",
			extractor = "lines",
			modifier = "weight_distance",
			filter = "filter_lines_around_cursor",
			visualizer = "hint_start",
			action = "remote_yank",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Yank Line",
				description = "Yanks the selected line without moving the cursor",
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Change[]
function presets.change(exclude)
	presets._register({
		c = {
			infer = true,
			collector = "lines",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Word",
				description = "Deletes the selected word and goes into insert mode",
				motion_state = {
					allow_quick_action = true,
				},
			},
		},
		ct = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_on_cursor_line_after_cursor",
			visualizer = "hint_start",
			action = "change_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Until Searched Text After Cursor",
				description = "Change until the searched for text after the cursor",
			},
		},
		cT = {
			collector = "lines",
			extractor = "text_search_1_char_until",
			filter = "filter_words_on_cursor_line_before_cursor",
			visualizer = "hint_start",
			action = "change_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Until Searched Text Before Cursor",
				description = "Change until the searched for text",
			},
		},
	}, exclude)
end

function presets.paste(exclude)
	presets._register({
		p = {
			infer = true,
			collector = "lines",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Paste",
				description = "Paste data",
				motion_state = {
					paste_mode = "after",
				},
			},
		},
		P = {
			infer = true,
			collector = "lines",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Paste",
				description = "Paste data",
				motion_state = {
					paste_mode = "before",
				},
			},
		},
	}, exclude)
end

function presets.misc(exclude)
	presets._register({
		["."] = {
			collector = "history",
			extractor = "pass_through",
			modifier = "default",
			filter = "first_target",
			visualizer = "pass_through",
			action = "run_motion",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Repeat Motion",
				description = "Repeat previous motion",
			},
		},
	}, exclude)

	-- Register gmd/gmy keymaps for multi-cursor edit
	if not (type(exclude) == "table" and exclude["gmd"] == false) then
		vim.keymap.set("n", "gmd", function()
			require("smart-motion.actions.multi_edit").run("delete")
		end, { desc = "Multi-cursor delete", noremap = true, silent = true })
	end

	if not (type(exclude) == "table" and exclude["gmy"] == false) then
		vim.keymap.set("n", "gmy", function()
			require("smart-motion.actions.multi_edit").run("yank")
		end, { desc = "Multi-cursor yank", noremap = true, silent = true })
	end
end

--- @param exclude? string[]
function presets.treesitter(exclude)
	-- Broad list of function-like node types across languages.
	-- Non-matching types are safely ignored per language.
	local function_node_types = {
		-- Lua
		"function_declaration",
		"function_definition",
		-- Python
		-- (function_definition covers Python)
		-- JavaScript / TypeScript
		"arrow_function",
		"method_definition",
		-- Rust
		"function_item",
		-- Go
		-- (function_declaration, method_declaration cover Go)
		"method_declaration",
		-- C / C++
		-- (function_definition covers C/C++)
		-- Java / C#
		-- (method_declaration covers Java/C#)
		-- Ruby
		"method",
	}

	local class_node_types = {
		"class_declaration",
		"class_definition",
		"struct_item",
		"struct_definition",
		"interface_declaration",
		"impl_item",
		"type_alias_declaration",
		"module",
	}

	local scope_node_types = {
		-- Control flow
		"if_statement", "if_expression", "else_clause", "elif_clause",
		"switch_statement", "switch_expression", "match_expression",
		"case_statement", "case_clause",
		-- Loops
		"while_statement", "while_expression",
		"for_statement", "for_expression", "for_in_statement", "for_of_statement",
		"do_statement", "loop_expression", "repeat_statement",
		-- Exception handling
		"try_statement", "catch_clause", "except_clause", "finally_clause",
		-- Blocks/closures
		"block", "closure_expression", "lambda", "lambda_expression",
		"with_statement", "do_block",
	}

	presets._register({
		["]]"] = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Function",
				description = "Jump to a function definition after the cursor",
				motion_state = {
					ts_node_types = function_node_types,
					multi_window = true,
				},
			},
		},
		["[["] = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Function",
				description = "Jump to a function definition before the cursor",
				motion_state = {
					ts_node_types = function_node_types,
					multi_window = true,
				},
			},
		},
		["]c"] = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Class",
				description = "Jump to a class/struct definition after the cursor",
				motion_state = {
					ts_node_types = class_node_types,
					multi_window = true,
				},
			},
		},
		["[c"] = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Class",
				description = "Jump to a class/struct definition before the cursor",
				motion_state = {
					ts_node_types = class_node_types,
					multi_window = true,
				},
			},
		},
		["]b"] = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Block/Scope",
				description = "Jump to a block/scope boundary after the cursor",
				motion_state = {
					ts_node_types = scope_node_types,
					multi_window = true,
				},
			},
		},
		["[b"] = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Block/Scope",
				description = "Jump to a block/scope boundary before the cursor",
				motion_state = {
					ts_node_types = scope_node_types,
					multi_window = true,
				},
			},
		},
	}, exclude)

	-- Argument/parameter container node types across languages.
	-- ts_yield_children yields each individual argument as a target.
	local arg_container_types = {
		"arguments",
		"argument_list",
		"parameters",
		"parameter_list",
		"formal_parameters",
	}

	-- Treesitter editing motions: operate on function names and arguments
	presets._register({
		-- Delete/Change/Yank around argument (includes separator)
		daa = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Around Argument",
				description = "Delete an argument including its separator",
				motion_state = {
					ts_node_types = arg_container_types,
					ts_yield_children = true,
					ts_around_separator = true,
				},
			},
		},
		caa = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "change",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Around Argument",
				description = "Change an argument (replaces its content)",
				motion_state = {
					ts_node_types = arg_container_types,
					ts_yield_children = true,
				},
			},
		},
		yaa = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "yank",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Around Argument",
				description = "Yank an argument",
				motion_state = {
					ts_node_types = arg_container_types,
					ts_yield_children = true,
				},
			},
		},

		-- Delete/Change/Yank function name
		dfn = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Function Name",
				description = "Delete a function's name",
				motion_state = {
					ts_node_types = function_node_types,
					ts_child_field = "name",
				},
			},
		},
		cfn = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "change",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Function Name",
				description = "Change a function's name (rename)",
				motion_state = {
					ts_node_types = function_node_types,
					ts_child_field = "name",
				},
			},
		},
		yfn = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "yank",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Function Name",
				description = "Yank a function's name",
				motion_state = {
					ts_node_types = function_node_types,
					ts_child_field = "name",
				},
			},
		},
	}, exclude)

	-- Register saa keymap for argument swap
	if not (type(exclude) == "table" and exclude["saa"] == false) then
		vim.keymap.set("n", "saa", function()
			require("smart-motion.actions.swap").run()
		end, { desc = "Swap two arguments", noremap = true, silent = true })
	end
end

--- @param exclude? string[]
function presets.diagnostics(exclude)
	presets._register({
		["]d"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Diagnostic",
				description = "Jump to a diagnostic after the cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
		["[d"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Diagnostic",
				description = "Jump to a diagnostic before the cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
		["]e"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Error",
				description = "Jump to an error diagnostic after the cursor",
				motion_state = {
					diagnostic_severity = vim.diagnostic.severity.ERROR,
					multi_window = true,
				},
			},
		},
		["[e"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Error",
				description = "Jump to an error diagnostic before the cursor",
				motion_state = {
					diagnostic_severity = vim.diagnostic.severity.ERROR,
					multi_window = true,
				},
			},
		},
	}, exclude)
end

--- Internal registration logic with optional filtering.
--- @param motions_list table<string, SmartMotionModule>
--- @param exclude? string[]
function presets._register(motions_list, user_overrides)
	local registries = require("smart-motion.core.registries"):get()
	user_overrides = user_overrides or {}

	-- Check if the entire preset is disabled
	if user_overrides == false then
		return
	end

	local final_motions = {}

	for name, motion in pairs(motions_list) do
		local override = user_overrides[name]

		-- Skip if this motion is explicitly disabled
		if override == false then
			goto continue
		end

		-- Merge override into motion config if table provider
		if type(override) == "table" then
			final_motions[name] = vim.tbl_deep_extend("force", motion, override)
		else
			-- No override, use default motion
			final_motions[name] = motion
		end

		::continue::
	end

	registries.motions.register_many_motions(final_motions)
end

return presets
