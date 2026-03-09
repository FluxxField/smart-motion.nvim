local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- Constants validation
-- =============================================================================

T["consts"] = MiniTest.new_set()

T["consts"]["DIRECTION has expected values"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.DIRECTION.AFTER_CURSOR, "after_cursor")
	expect.equality(consts.DIRECTION.BEFORE_CURSOR, "before_cursor")
	expect.equality(consts.DIRECTION.BOTH, "both")
end

T["consts"]["HINT_POSITION has expected values"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.HINT_POSITION.START, "start")
	expect.equality(consts.HINT_POSITION.END, "end")
end

T["consts"]["TARGET_TYPES has expected values"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.TARGET_TYPES.WORDS, "words")
	expect.equality(consts.TARGET_TYPES.LINES, "lines")
	expect.equality(consts.TARGET_TYPES.SEARCH, "search")
	expect.equality(consts.TARGET_TYPES.TREESITTER, "treesitter")
end

T["consts"]["EXIT_TYPE has all types"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.EXIT_TYPE.EARLY_EXIT, "early_exit")
	expect.equality(consts.EXIT_TYPE.DIRECT_HINT, "direct_hint")
	expect.equality(consts.EXIT_TYPE.AUTO_SELECT, "auto_select")
	expect.equality(consts.EXIT_TYPE.CONTINUE_TO_SELECTION, "continue_to_selection")
	expect.equality(consts.EXIT_TYPE.PIPELINE_EXIT, "pipeline_exit")
end

T["consts"]["SELECTION_MODE has expected values"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.SELECTION_MODE.FIRST, "first")
	expect.equality(consts.SELECTION_MODE.SECOND, "second")
end

T["consts"]["WORD_PATTERN is defined"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(type(consts.WORD_PATTERN), "string")
	expect.equality(#consts.WORD_PATTERN > 0, true)
end

T["consts"]["BIG_WORD_PATTERN is defined"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(type(consts.BIG_WORD_PATTERN), "string")
end

T["consts"]["JUMP_MOTIONS has standard vim motions"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.JUMP_MOTIONS.w, true)
	expect.equality(consts.JUMP_MOTIONS.e, true)
	expect.equality(consts.JUMP_MOTIONS.b, true)
	expect.equality(consts.JUMP_MOTIONS.j, true)
	expect.equality(consts.JUMP_MOTIONS.k, true)
end

T["consts"]["namespace is created"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(type(consts.ns_id), "number")
end

T["consts"]["numeric defaults are positive"] = function()
	local consts = require("smart-motion.consts")

	expect.equality(consts.FLOW_STATE_TIMEOUT_MS > 0, true)
	expect.equality(consts.HISTORY_MAX_SIZE > 0, true)
	expect.equality(consts.PINS_MAX_SIZE > 0, true)
end

return T
