local M = {}

--- Padding convention for surround operations.
--- Set via config: surround_pad = "opening" | "closing" | false
--- "opening" (default): opening chars (e.g. `(`) add padding → `( word )`
--- "closing": closing chars (e.g. `)`) add padding → `( word )`
--- false: no padding ever
M.pad_convention = "opening"

--- Delimiter pair definitions.
--- @type table<string, string>
M.PAIRS = {
	["("] = ")",
	["{"] = "}",
	["["] = "]",
	["<"] = ">",
	['"'] = '"',
	["'"] = "'",
	["`"] = "`",
}

--- Closing char → opening char aliases for asymmetric pairs.
--- @type table<string, string>
M.ALIASES = {
	[")"] = "(",
	["}"] = "{",
	["]"] = "[",
	[">"] = "<",
}

--- Special pair types that require a name prompt.
--- @type table<string, { type: string, prompt: string }>
M.SPECIAL_PAIRS = {
	t = { type = "tag", prompt = "Tag: " },
	f = { type = "function_call", prompt = "Function: " },
}

--- Builds open/close text for a special pair given a user-supplied name.
--- @param special_type string "tag" or "function_call"
--- @param name string The tag name or function name
--- @return { open: string, close: string, pad: boolean }|nil
function M.build_special_pair(special_type, name)
	if not name or name == "" then
		return nil
	end
	if special_type == "tag" then
		return { open = "<" .. name .. ">", close = "</" .. name .. ">", pad = false }
	elseif special_type == "function_call" then
		return { open = name .. "(", close = ")", pad = false }
	end
	return nil
end

--- Returns the open/close pair for any delimiter character.
--- Padding is determined by pad_convention and whether the char is asymmetric.
--- Symmetric pairs (quotes) never pad.
--- For special chars (t, f), returns a special result with a prompt field.
--- @param char string A single open or close delimiter character
--- @return { open: string, close: string, pad: boolean, special?: string, prompt?: string }|nil
function M.get_pair(char)
	-- Special pair types that need a name prompt
	if M.SPECIAL_PAIRS[char] then
		local special = M.SPECIAL_PAIRS[char]
		return { special = special.type, prompt = special.prompt }
	end

	local is_opening = M.PAIRS[char] ~= nil
	local is_closing = M.ALIASES[char] ~= nil

	local open, close
	if is_opening then
		open = char
		close = M.PAIRS[char]
	elseif is_closing then
		open = M.ALIASES[char]
		close = M.PAIRS[open]
	else
		return nil
	end

	-- Symmetric pairs (quotes) never pad
	local is_asymmetric = open ~= close
	local pad = false
	if is_asymmetric and M.pad_convention == "opening" then
		pad = is_opening
	elseif is_asymmetric and M.pad_convention == "closing" then
		pad = is_closing
	end

	return { open = open, close = close, pad = pad }
end

return M
