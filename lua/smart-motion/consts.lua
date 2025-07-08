--- @alias Direction "after_cursor" | "before_cursor" | "both"
--- @alias HintPosition "start" | "end"
--- @alias TargetType "words" | "lines" | "search"
--- @alias SelectionMode "first" | "second"
--- @alias SearchExitType "early_exit" | "direct_hint" | "auto_select" | "continue_to_selection"

local M = {}

M.ns_id = vim.api.nvim_create_namespace("smart_motion")

M.highlights = {
	HintSingle = "SmartMotionHint",
	FirstChar = "SmartMotionFirstChar",
	SecondChar = "SmartMotionSecondChar",
	DimmedChar = "SmartMotionDimmedChar",
}

---@type table<string, Direction>
M.DIRECTION = {
	AFTER_CURSOR = "after_cursor",
	BEFORE_CURSOR = "before_cursor",
	BOTH = "both",
}

---@type table<string, HintPosition>
M.HINT_POSITION = {
	START = "start",
	END = "end",
}

---@type table<string, TargetType>
M.TARGET_TYPES = {
	WORDS = "words",
	LINES = "lines",
	SEARCH = "search",
}

---@type table<string, TargetType>
M.TARGET_TYPES_BY_KEY = {
	w = "words",
	l = "lines",
	s = "search",
}

M.WORD_PATTERN = [[\k\+]]
M.WORD_WITH_PUNCTUATION_PATTERN = [[\k\+|[](){}.,=+%-]]
M.BIG_WORD_PATTERN = [[[^ \t]\+]]

---@type table<string, SelectionMode>
M.SELECTION_MODE = {
	FIRST = "first",
	SECOND = "second",
}

---@type table<string, SearchExitType>
M.EXIT_TYPE = {
	EARLY_EXIT = "early_exit",
	DIRECT_HINT = "direct_hint",
	AUTO_SELECT = "auto_select",
	CONTINUE_TO_SELECTION = "continue_to_selection",
	PIPELINE_EXIT = "pipeline_exit",
}

M.JUMP_MOTIONS = {
	w = true,
	e = true,
	b = true,
	ge = true,
	j = true,
	k = true,
	["{"] = true,
	["}"] = true,
}

M.FLOW_STATE_TIMEOUT_MS = 300

M.HISTORY_MAX_SIZE = 20

return M
