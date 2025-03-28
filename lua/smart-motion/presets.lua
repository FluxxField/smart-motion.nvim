local DIRECTION = require("smart-motion.consts").DIRECTION

local presets = {}

function presets.words(exclude)
	presets._register({
		w = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump",
			direction = DIRECTION.AFTER_CURSOR,
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
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump",
			direction = DIRECTION.BEFORE_CURSOR,
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
				visualizer = "hint_end",
			},
			pipeline_wrapper = "default",
			action = "jump",
			direction = DIRECTION.AFTER_CURSOR,
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
				visualizer = "hint_end",
			},
			pipeline_wrapper = "default",
			action = "jump",
			direction = DIRECTION.BEFORE_CURSOR,
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to End of Word before cursor",
				description = "Jumps to the end of a visible word target using labels before the cursor",
			},
		},
	}, exclude)
end

function presets.lines(exclude)
	presets._register({
		j = {
			pipeline = {
				collector = "lines",
				extractor = "lines",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump",
			direction = DIRECTION.AFTER_CURSOR,
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
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "jump",
			direction = DIRECTION.BEFORE_CURSOR,
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to Line before cursor",
				description = "Jumps to the start of the line before the cursor",
			},
		},
	}, exclude)
end

function presets.search(exclude)
	presets._register({
		s = {
			pipeline = {
				collector = "lines",
				extractor = "text_search",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "search",
			action = "jump",
			direction = DIRECTION.AFTER_CURSOR,
			map = true,
			modes = { "n", "v" },
			metadata = {
				label = "Jump to Searched Text",
				description = "Jumps to the start of the searched for text after the cursor",
			},
		},
	}, exclude)
end

function presets.delete(exclude)
	presets._register({
		d = {
			is_action = true,
			pipeline = {
				collector = "lines",
				visualizer = "hint_start",
			},
			direction = DIRECTION.AFTER_CURSOR,
			map = true,
			modes = { "n" },
			metadata = {
				label = "Delete Action",
				description = "Deletes based on motion provided",
			},
		},
		rdw = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "remote_delete",
			direction = DIRECTION.AFTER_CURSOR,
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
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "remote_delete",
			direction = DIRECTION.AFTER_CURSOR,
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Delete Line",
				description = "Deletes the selected line without moving the cursor",
			},
		},
	}, exclude)
end

function presets.yank(exclude)
	presets._register({
		y = {
			is_action = true,
			pipeline = {
				collector = "lines",
				visualizer = "hint_start",
			},
			direction = DIRECTION.AFTER_CURSOR,
			map = true,
			modes = { "n" },
			metadata = {
				label = "Yank Action",
				description = "Yanks based on the motion provided",
			},
		},
		ryw = {
			pipeline = {
				collector = "lines",
				extractor = "words",
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "remote_yank",
			direction = DIRECTION.AFTER_CURSOR,
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
				visualizer = "hint_start",
			},
			pipeline_wrapper = "default",
			action = "remote_yank",
			direction = DIRECTION.AFTER_CURSOR,
			map = true,
			modes = { "n" },
			metadata = {
				label = "Remote Yank Line",
				description = "Yanks the selected line without moving the cursor",
			},
		},
	}, exclude)
end

function presets.change(exclude)
	presets._register({
		c = {
			is_action = true,
			pipeline = {
				collector = "lines",
				visualizer = "hint_start",
			},
			direction = DIRECTION.AFTER_CURSOR,
			map = true,
			modes = { "n" },
			metadata = {
				label = "Change Word",
				description = "Deletes the selected word and goes into insert mode",
			},
		},
	}, exclude)
end

function presets._register(motions_list, exclude)
	local registries = require("smart-motion.core.registries"):get()
	exclude = exclude or {}

	if #exclude == 0 then
		registries.motions.register_many_motions(motions_list)
		return
	end

	local filtered_motions = {}

	for key, motion in pairs(motions_list) do
		if not vim.tbl_contains(exclude, key) then
			filtered_motions[key] = motion
		end
	end

	registries.motions.register_many_motions(filtered_motions)
end

return presets
