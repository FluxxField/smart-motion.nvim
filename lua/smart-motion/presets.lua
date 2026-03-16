local consts = require("smart-motion.consts")
local HINT_POSITION = consts.HINT_POSITION
local KEYWORD_PATTERN = consts.KEYWORD_PATTERN

---@type SmartMotionPresetsModule
local presets = {}

--- @param exclude? SmartMotionPresetKey.Words[]
function presets.words(exclude)
	presets._register({
		w = {
			composable = true,
			collector = "lines",
			extractor = "words",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			-- In op-pending mode, w is an exclusive motion (dw stops before the target word start),
			-- matching native vim behavior where dw does not eat the first char of the next word.
			modes = { "n", "v", o = { exclude_target = true } },
			metadata = {
				label = "Jump to Start of Word after cursor",
				description = "Jumps to the start of a visible word target using labels after the cursor",
			},
		},
		b = {
			composable = true,
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
			composable = true,
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
			composable = true,
			collector = "lines",
			extractor = "lines",
			filter = "filter_lines_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			count_passthrough = true,
			metadata = {
				label = "Jump to Line after cursor",
				description = "Jumps to the start of the line after the cursor",
				motion_state = {
					skip_jumplist = true,
				},
			},
		},
		k = {
			composable = true,
			collector = "lines",
			extractor = "lines",
			filter = "filter_lines_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "v", "o" },
			count_passthrough = true,
			metadata = {
				label = "Jump to Line before cursor",
				description = "Jumps to the start of the line before the cursor",
				motion_state = {
					skip_jumplist = true,
				},
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Search[]
function presets.search(exclude)
	presets._register({
		s = {
			composable = true,
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
		S = {
			composable = true,
			collector = "lines",
			extractor = "fuzzy_search",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Fuzzy Search",
				description = "Fuzzy search across all visible text with labeled results",
				motion_state = {
					multi_window = true,
				},
			},
		},
		f = {
			composable = true,
			collector = "lines",
			extractor = "text_search_2_char",
			filter = "filter_words_on_cursor_line_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "2 Character Find After Cursor",
				description = "Labels 2 Character Searches and jump to target (line-constrained)",
			},
		},
		F = {
			composable = true,
			collector = "lines",
			extractor = "text_search_2_char",
			filter = "filter_words_on_cursor_line_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "2 Character Find Before Cursor",
				description = "Labels 2 Character Searches and jump to target (line-constrained)",
			},
		},
		t = {
			composable = true,
			collector = "lines",
			extractor = "text_search_2_char_until",
			filter = "filter_words_on_cursor_line_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Till Character After Cursor",
				description = "Jump to just before the searched character after cursor (line-constrained)",
			},
		},
		T = {
			composable = true,
			collector = "lines",
			extractor = "text_search_2_char_until",
			filter = "filter_words_on_cursor_line_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Till Character Before Cursor",
				description = "Jump to just after the searched character before cursor (line-constrained)",
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
		ryw = {
			collector = "lines",
			extractor = "words",
			modifier = "weight_distance",
			filter = "filter_lines_around_cursor",
			visualizer = "hint_start",
			action = "yank_jump",
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
			action = "yank_jump",
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
	-- Function node types for quickfix output
	local function_node_types = {
		"function_declaration",
		"function_definition",
		"arrow_function",
		"method_definition",
		"function_item",
		"method_declaration",
		"method",
	}

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
		-- Quickfix output motions: collect targets and populate quickfix list
		["gQf"] = {
			collector = "treesitter",
			extractor = "pass_through",
			visualizer = "quickfix",
			action = "jump", -- Not used, visualizer exits early
			map = true,
			modes = { "n" },
			metadata = {
				label = "Functions to Quickfix",
				description = "List all functions in the buffer to quickfix",
				motion_state = {
					ts_node_types = function_node_types,
				},
			},
		},
		["gQd"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			visualizer = "quickfix",
			action = "jump",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Diagnostics to Quickfix",
				description = "List all diagnostics in the buffer to quickfix",
			},
		},
		["gQe"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			visualizer = "quickfix",
			action = "jump",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Errors to Quickfix",
				description = "List all error diagnostics to quickfix",
				motion_state = {
					diagnostic_severity = vim.diagnostic.severity.ERROR,
				},
			},
		},
		["gQg"] = {
			collector = "git_hunks",
			extractor = "pass_through",
			visualizer = "quickfix",
			action = "jump",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Git Hunks to Quickfix",
				description = "List all git changed regions to quickfix",
			},
		},
		-- Telescope output motions: fuzzy find targets
		["gTf"] = {
			collector = "treesitter",
			extractor = "pass_through",
			visualizer = "telescope",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Functions in Telescope",
				description = "Fuzzy find functions in the buffer",
				motion_state = {
					ts_node_types = function_node_types,
				},
			},
		},
		["gTd"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			visualizer = "telescope",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Diagnostics in Telescope",
				description = "Fuzzy find diagnostics in the buffer",
			},
		},
		["gTe"] = {
			collector = "diagnostics",
			extractor = "pass_through",
			visualizer = "telescope",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Errors in Telescope",
				description = "Fuzzy find error diagnostics",
				motion_state = {
					diagnostic_severity = vim.diagnostic.severity.ERROR,
				},
			},
		},
		["gTg"] = {
			collector = "git_hunks",
			extractor = "pass_through",
			visualizer = "telescope",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Git Hunks in Telescope",
				description = "Fuzzy find git changed regions",
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

	-- Register g. keymap for history browsing
	if not (type(exclude) == "table" and exclude["g."] == false) then
		vim.keymap.set("n", "g.", function()
			require("smart-motion.actions.history_browse").run()
		end, { desc = "Browse motion history", noremap = true, silent = true })
	end

	-- Register gp keymap for toggling pins
	if not (type(exclude) == "table" and exclude["gp"] == false) then
		vim.keymap.set("n", "gp", function()
			require("smart-motion.core.history").toggle_pin()
		end, { desc = "Toggle pin at cursor", noremap = true, silent = true })
	end

	-- Register g1-g9 keymaps for direct pin jumps
	for i = 1, 9 do
		local key = "g" .. i
		if not (type(exclude) == "table" and exclude[key] == false) then
			vim.keymap.set("n", key, function()
				require("smart-motion.core.history").jump_to_pin(i)
			end, { desc = "Jump to pin " .. i, noremap = true, silent = true })
		end
	end

	-- Register g0 keymap for jumping to most recent history entry
	if not (type(exclude) == "table" and exclude["g0"] == false) then
		vim.keymap.set("n", "g0", function()
			require("smart-motion.core.history").jump_to_recent()
		end, { desc = "Jump to most recent location", noremap = true, silent = true })
	end

	-- Register gp1-gp9 keymaps for setting pins at specific slots
	for i = 1, 9 do
		local key = "gp" .. i
		if not (type(exclude) == "table" and exclude[key] == false) then
			vim.keymap.set("n", key, function()
				require("smart-motion.core.history").set_pin_at(i)
			end, { desc = "Set pin at slot " .. i, noremap = true, silent = true })
		end
	end

	-- Register gP keymap for toggling global pins (prompts for letter)
	if not (type(exclude) == "table" and exclude["gP"] == false) then
		vim.keymap.set("n", "gP", function()
			require("smart-motion.core.history").toggle_global_pin()
		end, { desc = "Toggle global pin (prompts A-Z)", noremap = true, silent = true })
	end

	-- Register g<letter> keymaps for jumping to global pins (A-Z)
	-- Skip letters used by other SmartMotion keymaps:
	--   P = toggle global pin (gP), S = treesitter incremental select (gS)
	local reserved_global_pin_letters = { P = true, S = true }
	for c = 65, 90 do -- ASCII A-Z
		local letter = string.char(c)
		if not reserved_global_pin_letters[letter] then
			local key = "g" .. letter
			if not (type(exclude) == "table" and exclude[key] == false) then
				vim.keymap.set("n", key, function()
					require("smart-motion.core.history").jump_to_global_pin(letter)
				end, { desc = "Jump to global pin " .. letter, noremap = true, silent = true })
			end
		end
	end

	-- Register gP<letter> keymaps for setting global pins directly (A-Z)
	for c = 65, 90 do -- ASCII A-Z
		local letter = string.char(c)
		local key = "gP" .. letter
		if not (type(exclude) == "table" and exclude[key] == false) then
			vim.keymap.set("n", key, function()
				require("smart-motion.core.history").set_global_pin(letter)
			end, { desc = "Set global pin " .. letter, noremap = true, silent = true })
		end
	end
end

--- @param exclude? table
function presets.surround(exclude)
	-- Apply surround_pad config to pair_defs
	local cfg = require("smart-motion.config").validated
	if cfg then
		local pair_defs = require("smart-motion.utils.pair_defs")
		pair_defs.pad_convention = cfg.surround_pad
	end

	local pair_types = {
		{ "(", ")" },
		{ "[", "]" },
		{ "{", "}" },
		{ "<", ">" },
		{ '"', '"' },
		{ "'", "'" },
		{ "`", "`" },
	}

	-- Register pair text objects: accessed via i/a prefix in infer and x/o keymaps.
	-- For asymmetric pairs, both open and close chars are registered (e.g. "(" and ")").
	local textobjects = {}

	for _, pair in ipairs(pair_types) do
		local open = pair[1]
		local close = pair[2]

		local entry = {
			collector = "pairs",
			extractor = "pairs",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			metadata = {
				label = open .. close .. " pair",
				description = "Delimiter pair " .. open .. close,
				motion_state = {
					pair_chars = { { open, close } },
					is_textobject = true,
				},
			},
			inside = { pair_scope = "inside" },
			around = { pair_scope = "around" },
			surround = { pair_scope = "surround", is_surround = true },
			default = "around",
		}

		textobjects[open] = entry
		if open ~= close then
			textobjects[close] = vim.deepcopy(entry)
		end
	end

	-- HTML/XML tag textobject
	textobjects["t"] = {
		collector = "tags",
		extractor = "pairs",
		modifier = "weight_distance",
		filter = "filter_visible",
		visualizer = "hint_start",
		metadata = {
			label = "Tag",
			description = "HTML/XML tag text object",
			motion_state = {
				is_textobject = true,
			},
		},
		inside = { pair_scope = "inside" },
		around = { pair_scope = "around" },
		surround = { pair_scope = "surround", is_surround = true },
		default = "around",
	}

	-- Quote alias: matches any quote type (", ', `)
	textobjects["q"] = {
		collector = "pairs",
		extractor = "pairs",
		modifier = "weight_distance",
		filter = "filter_visible",
		visualizer = "hint_start",
		metadata = {
			label = "Any quote",
			description = "Nearest quote pair (double, single, or backtick)",
			motion_state = {
				pair_chars = { { '"', '"' }, { "'", "'" }, { "`", "`" } },
				is_textobject = true,
			},
		},
		inside = { pair_scope = "inside" },
		around = { pair_scope = "around" },
		surround = { pair_scope = "surround", is_surround = true },
		default = "around",
	}

	presets._register_textobjects(textobjects, exclude)

	-- Build excluded table from exclude param
	local excluded = {}
	if type(exclude) == "table" then
		for k, v in pairs(exclude) do
			if v == false then
				excluded[k] = true
			end
		end
	end

	-- Surround operators: ds, cs, ys
	-- ds/cs pre-set textobject_key = "surround" so infer looks up the next char
	-- directly in the textobject registry and uses the surround overrides.
	presets._register({
		ds = {
			infer = true,
			action_key = "d",
			collector = "pairs",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "surround",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Surround",
				description = "Delete surrounding delimiter pair",
				motion_state = {
					textobject_key = "surround",
					allow_quick_action = false,
				},
			},
		},
		cs = {
			infer = true,
			action_key = "c",
			collector = "pairs",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "surround",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Surround",
				description = "Change surrounding delimiter pair",
				motion_state = {
					textobject_key = "surround",
					allow_quick_action = false,
				},
			},
		},
		ys = {
			infer = true,
			collector = "lines",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "surround_add",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Surround Add",
				description = "Add surround: ys{i/a}{motion}{delimiter}",
				motion_state = {
					allow_quick_action = false,
					ia_resolve_composable = true,
					word_pattern = KEYWORD_PATTERN,
					expansion_enabled = true,
				},
			},
		},
	}, exclude)

	-- Register gza (standalone surround add with word hints)
	presets._register({
		gza = {
			collector = "lines",
			extractor = "words",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "surround_add",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Surround Add (words)",
				description = "Show word hints, pick target, then type delimiter to wrap",
				motion_state = {
					word_pattern = KEYWORD_PATTERN,
					expansion_enabled = true,
				},
			},
		},
	}, exclude)

	-- Register gzp (paste surround with word hints)
	presets._register({
		gzp = {
			collector = "lines",
			extractor = "words",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "surround_paste",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Surround Paste",
				description = "Wrap a word target with the previously yanked delimiter pair",
				motion_state = {
					word_pattern = KEYWORD_PATTERN,
				},
			},
		},
	}, exclude)

	-- Register S keymap for visual surround (no conflict: existing S is n/o only)
	if not excluded["S"] then
		vim.keymap.set("x", "S", function()
			require("smart-motion.actions.surround_visual").run()
		end, { desc = "Surround visual selection", noremap = true, silent = true })
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
		"if_statement",
		"if_expression",
		"else_clause",
		"elif_clause",
		"switch_statement",
		"switch_expression",
		"match_expression",
		"case_statement",
		"case_clause",
		-- Loops
		"while_statement",
		"while_expression",
		"for_statement",
		"for_expression",
		"for_in_statement",
		"for_of_statement",
		"do_statement",
		"loop_expression",
		"repeat_statement",
		-- Exception handling
		"try_statement",
		"catch_clause",
		"except_clause",
		"finally_clause",
		-- Blocks/closures
		"block",
		"closure_expression",
		"lambda",
		"lambda_expression",
		"with_statement",
		"do_block",
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

	-- Text objects: registered in the textobject registry, accessed via i/a prefix.
	-- The i/a keymaps in x/o modes dispatch to the textobject pipeline automatically.
	-- Operators (d/y/c) access textobjects via i/a prefix handling in infer.
	presets._register_textobjects({
		f = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			metadata = {
				label = "Function",
				description = "Function text object",
				motion_state = {
					ts_node_types = function_node_types,
					is_textobject = true,
				},
			},
			inside = { ts_inner_body = true },
			around = {},
			surround = {
				_collector_override = "function_calls",
				_extractor_override = "pairs",
				pair_scope = "surround",
				is_surround = true,
			},
			default = "around",
		},
		c = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			metadata = {
				label = "Class",
				description = "Class/struct text object",
				motion_state = {
					ts_node_types = class_node_types,
					is_textobject = true,
				},
			},
			inside = { ts_inner_body = true },
			around = {},
			default = "around",
		},
		a = {
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			metadata = {
				label = "Argument",
				description = "Argument/parameter text object",
				motion_state = {
					ts_node_types = arg_container_types,
					ts_yield_children = true,
					is_textobject = true,
				},
			},
			inside = {},
			around = { ts_around_separator = true },
			default = "inside",
		},
	}, exclude)

	-- fn stays as a composable motion (not a textobject — no i/a prefix)
	presets._register({
		fn = {
			composable = true,
			collector = "treesitter",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "textobject_select",
			map = true,
			modes = { "o" },
			metadata = {
				label = "Function Name",
				description = "Select a function name",
				motion_state = {
					ts_node_types = function_node_types,
					ts_child_field = "name",
					is_textobject = true,
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

	-- Register gS keymap for treesitter incremental selection
	if not (type(exclude) == "table" and exclude["gS"] == false) then
		vim.keymap.set({ "n", "x" }, "gS", function()
			require("smart-motion.actions.treesitter_select").run()
		end, { desc = "Treesitter incremental select (; expand, , shrink)", noremap = true, silent = true })
	end

	-- Register R keymap for treesitter search (search text → select surrounding node)
	if not (type(exclude) == "table" and exclude["R"] == false) then
		vim.keymap.set({ "n", "x", "o" }, "R", function()
			-- Capture mode/operator now since they change once the callback returns.
			-- The function runs the interactive search inside the callback; only the
			-- final operation (d/y/c) is deferred via vim.schedule inside M.run().
			local current_mode = vim.fn.mode(true)
			local operator = current_mode:find("o") and vim.v.operator or nil
			require("smart-motion.actions.treesitter_search").run(current_mode, operator)
		end, { desc = "Treesitter search (select node containing match)", noremap = true })
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

--- @param exclude? SmartMotionPresetKey.Git[]
function presets.git(exclude)
	presets._register({
		["]g"] = {
			collector = "git_hunks",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Git Hunk",
				description = "Jump to a git changed region after the cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
		["[g"] = {
			collector = "git_hunks",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Git Hunk",
				description = "Jump to a git changed region before the cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Quickfix[]
function presets.quickfix(exclude)
	presets._register({
		["]q"] = {
			collector = "quickfix",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Quickfix Entry",
				description = "Jump to a quickfix entry after the cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
		["[q"] = {
			collector = "quickfix",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Quickfix Entry",
				description = "Jump to a quickfix entry before the cursor",
				motion_state = {
					multi_window = true,
				},
			},
		},
		["]l"] = {
			collector = "quickfix",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_after_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Next Location List Entry",
				description = "Jump to a location list entry after the cursor",
				motion_state = {
					multi_window = true,
					use_loclist = true,
				},
			},
		},
		["[l"] = {
			collector = "quickfix",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_words_before_cursor",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Previous Location List Entry",
				description = "Jump to a location list entry before the cursor",
				motion_state = {
					multi_window = true,
					use_loclist = true,
				},
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Marks[]
function presets.marks(exclude)
	-- Register pipeline-based motion for jumping to marks
	presets._register({
		["g'"] = {
			collector = "marks",
			extractor = "pass_through",
			modifier = "weight_distance",
			filter = "filter_visible",
			visualizer = "hint_start",
			action = "jump_centered",
			map = true,
			modes = { "n", "o" },
			metadata = {
				label = "Jump to Mark",
				description = "Show labels on all marks, jump to selected one",
				motion_state = {
					multi_window = true,
				},
			},
		},
	}, exclude)

	-- Build excluded table from exclude param
	local excluded = {}
	if type(exclude) == "table" then
		for _, key in ipairs(exclude) do
			excluded[key] = true
		end
	end

	-- Register gm keymap for setting mark at target
	if not excluded["gm"] then
		vim.keymap.set("n", "gm", function()
			require("smart-motion.actions.set_mark").run()
		end, { desc = "Set mark at labeled target", noremap = true, silent = true })
	end
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
			-- Route label customization keys into metadata.motion_state
			-- to avoid conflict with the motion entry's `keys` property (used for action key mapping)
			if override.keys or override.exclude_keys then
				override = vim.tbl_deep_extend("force", {}, override)
				override.metadata = override.metadata or {}
				override.metadata.motion_state = override.metadata.motion_state or {}
				if override.keys then
					override.metadata.motion_state.label_keys = override.keys
					override.keys = nil
				end
				if override.exclude_keys then
					override.metadata.motion_state.exclude_label_keys = override.exclude_keys
					override.exclude_keys = nil
				end
			end
			final_motions[name] = vim.tbl_deep_extend("force", motion, override)
		else
			-- No override, use default motion
			final_motions[name] = motion
		end

		::continue::
	end

	registries.motions.register_many_motions(final_motions)
end

--- Internal textobject registration logic with optional filtering.
--- Same override/exclude pattern as _register for consistency.
--- @param textobjects_list table<string, SmartMotionTextobjectEntry>
--- @param user_overrides? table
function presets._register_textobjects(textobjects_list, user_overrides)
	local registries = require("smart-motion.core.registries"):get()
	user_overrides = user_overrides or {}

	if user_overrides == false then
		return
	end

	local final = {}

	for key, entry in pairs(textobjects_list) do
		local override = user_overrides[key]

		if override == false then
			goto continue
		end

		if type(override) == "table" then
			final[key] = vim.tbl_deep_extend("force", entry, override)
		else
			final[key] = entry
		end

		::continue::
	end

	registries.motions.register_many_textobjects(final)

	-- Register i/a keymaps in x/o modes (idempotent, only registers once)
	require("smart-motion.core.textobject_keymaps").setup()
end

return presets
