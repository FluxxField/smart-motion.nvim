local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionPresetsModule
local presets = {}

--- @param exclude? SmartMotionPresetKey.Words[]
function presets.words(exclude)
	presets._register({
		w = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				filter = "filter_words_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump_centered",
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to Start of Word after cursor",
				description = "Jumps to the start of a visible word target using labels after the cursor",
			},
		},
		b = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				filter = "filter_words_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump_centered",
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to Start of Word before cursor",
				description = "Jumps to the start of a visible word target using labels before the cursor",
			},
		},
		e = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				filter = "filter_words_after_cursor",
				visualizer = "hint_end",
			},
			pipeline_wrapper = "default",
			action = "jump_centered",
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to End of Word after cursor",
				description = "Jumps to the end of a visible word target using labels after the cursor",
			},
		},
		ge = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				filter = "filter_words_before_cursor",
				visualizer = "hint_end",
			},
			pipeline_wrapper = "default",
			action = "jump_centered",
			map = true,
			modes = { "n", "v" },
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
			pipeline = {
				collector = "lines",
				extractor = "lines",
				filter = "filter_lines_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump_centered",
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to Line after cursor",
				description = "Jumps to the start of the line after the cursor",
			},
		},
		k = {
			pipeline = {
				collector = "lines",
				extractor = "lines",
				filter = "filter_lines_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump_centered",
			map = true,
			modes = { "n", "v" },
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
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "live_search",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Jump to Searched Text After Cursor",
				description = "Jumps to the start of the searched for text",
			},
		},
		S = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "live_search",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Jump to Searched Text After Cursor",
				description = "Jumps to the start of the searched for text",
			},
		},
		f = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_2_char",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "2 Character Find After Cursor",
				description = "Labels 2 Character Searches and jump to target",
			},
		},
		F = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_2_char",
			action = "jump_centered",
			map = true,
			modes = { "n" },
			metadata = {
				label = "2 Character Find Before Cursor",
				description = "Labels 2 Character Searches and jump to target",
			},
		},
	}, exclude)
end

--- @param exclude? SmartMotionPresetKey.Delete[]
function presets.delete(exclude)
	presets._register({
		d = {
			is_action = true,
			pipeline = {
				collector = "lines",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Action",
				description = "Deletes based on motion provided",
			},
		},
		dt = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_on_cursor_line_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_1_char",
			action = "delete_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Until Searched Text",
				description = "Deletes until the searched for text",
			},
		},
		dT = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_on_cursor_line_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_1_char",
			action = "delete_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Until Searched Text",
				description = "Deletes until the searched for text",
			},
		},
		rdw = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "remote_delete",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Delete Word",
				description = "Deletes the selected word without moving the cursor",
			},
		},
		rdl = {
			pipeline = {
				collector = "lines",
				extractor = "lines",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
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
			is_action = true,
			pipeline = {
				collector = "lines",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Action",
				description = "Yanks based on the motion provided",
			},
		},
		yt = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_on_cursor_line_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_1_char",
			action = "yank_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Until Searched Text After Cursor",
				description = "Yank until the searched for text",
			},
		},
		yT = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_on_cursor_line_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_1_char",
			action = "yank_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Until Searched Text Before Cursor",
				description = "Yank until the searched for text",
			},
		},
		ryw = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "remote_yank",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Yank Word",
				description = "Yanks the selected word without moving the cursor",
			},
		},
		ryl = {
			pipeline = {
				collector = "lines",
				extractor = "lines",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
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
			is_action = true,
			pipeline = {
				collector = "lines",
				filter = "filter_visible",
				visualizer = "hint_start",
			},
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Word",
				description = "Deletes the selected word and goes into insert mode",
			},
		},
		ct = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_on_cursor_line_after_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_1_char",
			action = "change_until",
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Until Searched Text After Cursor",
				description = "Change until the searched for text",
			},
		},
		cT = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				filter = "filter_words_on_cursor_line_before_cursor",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "text_search_1_char",
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

	for key, motion in pairs(motions_list) do
		local override = user_overrides[key]

		-- Skip if this motion is explicitly disabled
		if override == false then
			goto continue
		end

		-- Merge override into motion config if table provider
		if type(override) == "table" then
			final_motions[key] = vim.tbl_deep_extend("force", motion, override)
		else
			-- No override, use default motion
			final_motions[key] = motion
		end

		::continue::
	end

	registries.motions.register_many_motions(final_motions)
end

return presets
