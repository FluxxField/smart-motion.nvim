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
	BOTH = "BOTH",
}

M.HINT_POSITION = {
	START = "start",
	END = "end",
}

M.TARGET_TYPES = {
	WORDS = "words",
	LINES = "lines",
	SEARCH = "search",
}

M.TARGET_TYPES_BY_KEY = {
	w = "words",
	l = "lines",
	s = "search",
}

M.WORD_PATTERN = [[\k\+]]

M.SELECTION_MODE = {
	FIRST = "first",
	SECOND = "second",
}

return M
