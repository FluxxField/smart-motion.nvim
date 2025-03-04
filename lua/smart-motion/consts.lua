local M = {}

M.ns_id = vim.api.nvim_create_namespace("smart_motion")

M.highlights = {
	HintSingle = "SmartMotionHint",
	FirstChar = "SmartMotionFirstChar",
	SecondChar = "SmartMotionSecondChar",
	DimmedChar = "SmartMotionDimmedChar",
}

M.DIRECTION = {
	AFTER_CURSOR = "after_cursor",
	BEFORE_CURSOR = "before_cursor",
}

M.HINT_POSITION = {
	START = "start",
	END = "end",
}

M.TARGET_TYPES = {
	WORD = "word",
	CHAR = "char",
	LINE = "line",
}

--
-- Word Motion constants
--
M.WORD_MOTIONS = {
	w = "w",
	b = "b",
	e = "e",
	ge = "ge",
}

M.word_motion_direction = {
	[M.WORD_MOTIONS.w] = M.DIRECTION.AFTER_CURSOR,
	[M.WORD_MOTIONS.b] = M.DIRECTION.BEFORE_CURSOR,
	[M.WORD_MOTIONS.e] = M.DIRECTION.AFTER_CURSOR,
	[M.WORD_MOTIONS.ge] = M.DIRECTION.BEFORE_CURSOR,
}

M.word_motion_hint_position = {
	[M.WORD_MOTIONS.w] = M.HINT_POSITION.START,
	[M.WORD_MOTIONS.b] = M.HINT_POSITION.START,
	[M.WORD_MOTIONS.e] = M.HINT_POSITION.END,
	[M.WORD_MOTIONS.ge] = M.HINT_POSITION.END,
}

M.WORD_PATTERN = [[\k\+]]

M.SELECTION_MODE = {
	FIRST = "first",
	SECOND = "second",
}

return M
