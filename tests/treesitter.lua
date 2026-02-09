-- SmartMotion Playground: Treesitter Motions
-- Presets: ]], [[, ]c, [c, ]b, [b, af, if, ac, ic, aa, ia, fn, saa, gS, R
--
-- INSTRUCTIONS:
--   ]]  → jump to next function definition
--   [[  → jump to previous function definition
--   ]c  → jump to next class/module table
--   [c  → jump to previous class/module table
--   ]b  → jump to next block/scope (if, for, while, pcall)
--   [b  → jump to previous block/scope
--
-- TEXT OBJECTS (work in visual + operator-pending — compose with ANY operator):
--   af  → around function (select entire function)
--   if  → inside function (select function body only)
--   ac  → around class/struct
--   ic  → inside class/struct body
--   aa  → around argument (including separator/comma)
--   ia  → inside argument (without separator)
--   fn  → function name (select just the name identifier)
--
-- COMPOSITION (text objects work with any operator via infer fallthrough):
--   daf → delete around function       vaf → visually select function
--   cif → change inside function        yaa → yank around argument
--   gqaf → format function              =af → auto-indent function
--   >ic → indent inside class           gUfn → uppercase function name
--   dfn → delete function name (multi-char infer: d + fn)
--   cfn → change function name          yfn → yank function name
--
-- MULTI-CHAR INFER (fn vs f):
--   dfn  (typed quickly) → resolves as "fn" composable → labels on function names
--   df   (typed + pause) → resolves as "f" (find-char) after timeoutlen
--
-- OTHER:
--   saa → swap two arguments (pick first, pick second, they swap)
--   gS  → treesitter incremental select (start at cursor, ; expand, , shrink)
--   R   → treesitter search (search text → select surrounding node)
--
-- MULTI-WINDOW:
--   :vsplit tests/search.lua
--   Press ]] — labels should appear on functions in BOTH windows

-- ── Section 1: Function definitions for ]] and [[ ─────────────

local function parse_csv(input, delimiter)
	delimiter = delimiter or ","
	local result = {}
	local row = {}
	local field = ""
	local in_quotes = false

	for i = 1, #input do
		local char = input:sub(i, i)
		if char == '"' then
			in_quotes = not in_quotes
		elseif char == delimiter and not in_quotes then
			row[#row + 1] = field
			field = ""
		elseif char == "\n" and not in_quotes then
			row[#row + 1] = field
			result[#result + 1] = row
			row = {}
			field = ""
		else
			field = field .. char
		end
	end
	row[#row + 1] = field
	result[#result + 1] = row
	return result
end

local function serialize_json(value, indent)
	indent = indent or 0
	local t = type(value)
	if t == "string" then
		return '"' .. value:gsub('"', '\\"') .. '"'
	elseif t == "number" or t == "boolean" then
		return tostring(value)
	elseif t == "nil" then
		return "null"
	elseif t == "table" then
		local is_array = #value > 0
		local parts = {}
		local pad = string.rep("  ", indent + 1)
		if is_array then
			for _, v in ipairs(value) do
				parts[#parts + 1] = pad .. serialize_json(v, indent + 1)
			end
			return "[\n" .. table.concat(parts, ",\n") .. "\n" .. string.rep("  ", indent) .. "]"
		else
			for k, v in pairs(value) do
				parts[#parts + 1] = pad .. '"' .. tostring(k) .. '": ' .. serialize_json(v, indent + 1)
			end
			return "{\n" .. table.concat(parts, ",\n") .. "\n" .. string.rep("  ", indent) .. "}"
		end
	end
end

local function debounce(fn, delay)
	local timer = nil
	return function(...)
		local args = { ... }
		if timer then
			timer:stop()
		end
		timer = vim.loop.new_timer()
		timer:start(delay, 0, function()
			timer:stop()
			timer:close()
			timer = nil
			vim.schedule(function()
				fn(unpack(args))
			end)
		end)
	end
end

local function throttle(fn, interval)
	local last_call = 0
	local queued = nil
	return function(...)
		local now = vim.loop.now()
		if now - last_call >= interval then
			last_call = now
			fn(...)
		else
			queued = { ... }
			vim.defer_fn(function()
				if queued then
					last_call = vim.loop.now()
					fn(unpack(queued))
					queued = nil
				end
			end, interval - (now - last_call))
		end
	end
end

local function memoize(fn)
	local cache = {}
	return function(...)
		local key = table.concat({ ... }, "\0")
		if cache[key] == nil then
			cache[key] = fn(...)
		end
		return cache[key]
	end
end

-- Try: ]] from top — labels on parse_csv, serialize_json, debounce, throttle, memoize
-- Try: [[ from bottom — labels on same functions going backward

-- ── Section 2: Module tables for ]c and [c ────────────────────

local Logger = {}
Logger.__index = Logger

function Logger.new(name, level)
	return setmetatable({
		name = name,
		level = level or "info",
		handlers = {},
		buffer = {},
	}, Logger)
end

function Logger:log(level, message, data)
	local entry = {
		timestamp = os.time(),
		level = level,
		logger = self.name,
		message = message,
		data = data,
	}
	self.buffer[#self.buffer + 1] = entry
	for _, handler in ipairs(self.handlers) do
		handler(entry)
	end
end

function Logger:add_handler(handler)
	self.handlers[#self.handlers + 1] = handler
end

local EventEmitter = {}
EventEmitter.__index = EventEmitter

function EventEmitter.new()
	return setmetatable({
		listeners = {},
		once_listeners = {},
	}, EventEmitter)
end

function EventEmitter:on(event, callback)
	if not self.listeners[event] then
		self.listeners[event] = {}
	end
	self.listeners[event][#self.listeners[event] + 1] = callback
end

function EventEmitter:once(event, callback)
	if not self.once_listeners[event] then
		self.once_listeners[event] = {}
	end
	self.once_listeners[event][#self.once_listeners[event] + 1] = callback
end

function EventEmitter:emit(event, ...)
	local callbacks = self.listeners[event] or {}
	for _, cb in ipairs(callbacks) do
		cb(...)
	end
	local once = self.once_listeners[event] or {}
	for _, cb in ipairs(once) do
		cb(...)
	end
	self.once_listeners[event] = nil
end

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(initial_state, transitions)
	return setmetatable({
		current = initial_state,
		transitions = transitions,
		history = { initial_state },
		on_enter = {},
		on_exit = {},
	}, StateMachine)
end

function StateMachine:transition(event)
	local state_transitions = self.transitions[self.current]
	if not state_transitions or not state_transitions[event] then
		return false, "No transition for event '" .. event .. "' in state '" .. self.current .. "'"
	end
	local old_state = self.current
	local new_state = state_transitions[event]
	if self.on_exit[old_state] then
		self.on_exit[old_state](old_state, event)
	end
	self.current = new_state
	self.history[#self.history + 1] = new_state
	if self.on_enter[new_state] then
		self.on_enter[new_state](new_state, event)
	end
	return true
end

-- Try: ]c from top — labels on Logger, EventEmitter, StateMachine
-- Try: [c from bottom — same in reverse

-- ── Section 3: Blocks/scopes for ]b and [b ────────────────────

local function complex_processor(data, options)
	if not data then
		return nil, "no data provided"
	end

	if options.validate then
		for i, item in ipairs(data) do
			if not item.id then
				return nil, "item " .. i .. " missing id"
			end
		end
	end

	local results = {}
	for _, item in ipairs(data) do
		if item.type == "alpha" then
			local processed = item.value * 2
			if processed > options.threshold then
				results[#results + 1] = { id = item.id, result = processed, capped = true }
			else
				results[#results + 1] = { id = item.id, result = processed, capped = false }
			end
		elseif item.type == "beta" then
			local ok, transformed = pcall(function()
				return options.transform(item.value)
			end)
			if ok then
				results[#results + 1] = { id = item.id, result = transformed }
			end
		end
	end

	while #results < options.min_results do
		results[#results + 1] = { id = "padding", result = 0 }
	end

	if options.sort then
		table.sort(results, function(a, b)
			return a.result > b.result
		end)
	end

	return results
end

-- Try: ]b from top — labels on if, for, while, pcall blocks
-- Try: [b from bottom — same in reverse

-- ── Section 4: Arguments for aa, ia, saa ────────────────────

-- TEXT OBJECTS (visual / operator-pending):
-- Try: vaa near a function call — labels on arguments, visually select one (with comma)
-- Try: via — same but without separator
-- Try: daa — delete around argument (operator composes via infer fallthrough)
-- Try: caa — change around argument
-- Try: yaa — yank around argument (check :reg ")
-- Try: gUaa — uppercase an argument
--
-- STANDALONE:
-- Try: saa — pick two arguments, they swap positions

local function create_user(name, email, role, department, active)
	return {
		name = name,
		email = email,
		role = role,
		department = department,
		active = active,
	}
end

local function send_notification(recipient, subject, body, priority, channel)
	print(string.format("[%s/%s] To: %s | %s: %s", priority, channel, recipient, subject, body))
end

local function configure_server(host, port, workers, timeout, ssl, log_path)
	return {
		address = host .. ":" .. tostring(port),
		workers = workers,
		timeout = timeout,
		ssl = ssl,
		log_path = log_path,
	}
end

-- Usage with many arguments — good saa test
local user = create_user("Alice", "alice@example.com", "admin", "engineering", true)
send_notification("bob@example.com", "Alert", "System update required", "high", "email")
local server = configure_server("0.0.0.0", 8080, 4, 30000, true, "/var/log/app.log")

-- Try: saa on the create_user call — swap "Alice" with "admin" for example

-- ── Section 5: Function names (fn text object + multi-char infer) ──

-- TEXT OBJECT (operator-pending only — no visual mode to avoid f delay):
-- Try: dfn (type quickly) — multi-char infer resolves "fn", labels on function names, delete one
-- Try: cfn (type quickly) — same, change one (enters insert mode)
-- Try: yfn (type quickly) — same, yank one
-- Try: df  (type + pause) — resolves as find-char (2-char search), NOT function name
--
-- ARBITRARY OPERATORS (via op-pending fn keymap):
-- Try: gUfn — uppercase a function name
-- Try: gqfn — format a function name

local function validate_email(address)
	return address:match("^[%w.]+@[%w.]+%.%w+$") ~= nil
end

local function validate_phone(number)
	return number:match("^%+?%d[%d%-%(%) ]+%d$") ~= nil
end

local function validate_url(url)
	return url:match("^https?://[%w%-%.]+%.[%w]+") ~= nil
end

local function normalize_whitespace(text)
	return text:gsub("%s+", " "):match("^%s*(.-)%s*$")
end

local function escape_html(text)
	local entities = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }
	return text:gsub('[&<>"]', entities)
end

local function unescape_html(text)
	local entities = { ["&amp;"] = "&", ["&lt;"] = "<", ["&gt;"] = ">", ["&quot;"] = '"' }
	return text:gsub("&%w+;", entities)
end

-- Try: dfn (quick) — labels appear on validate_email, validate_phone, validate_url, etc.
-- Try: cfn on validate_email — deletes the name, enters insert mode to type new one
-- Try: df (pause) — should trigger find-char, NOT function name

-- ── Section 6: Treesitter Incremental Select (gS) ─────────────

-- INCREMENTAL SELECT TEST:
-- 1. Place cursor inside a function, on a variable, or in an expression
-- 2. Press gS — visual selection starts on smallest node at cursor
-- 3. Press ; — selection expands to parent node
-- 4. Press ; again — expands further up the tree
-- 5. Press , — selection shrinks to child node
-- 6. Press Enter — confirms selection
-- 7. Press ESC — cancels and exits visual mode
--
-- Watch the echo area: shows node type and position [n/total]

local function incremental_select_demo()
	local deeply = {
		nested = {
			data = {
				value = calculate_something(1, 2, 3),
			},
		},
	}
	-- Try: place cursor on "calculate_something", press gS
	-- Then: ; to expand to call expression, ; to expand to table field, etc.
	return deeply.nested.data.value
end

local function calculate_something(a, b, c)
	local result = (a + b) * c
	-- Try: place cursor on "a", press gS, then ; repeatedly
	-- Watch: identifier → binary_expression → parenthesized_expression → etc.
	if result > 100 then
		return result - 50
	else
		return result + 50
	end
end

-- ── Section 7: Treesitter Search (R) ──────────────────────────

-- TREESITTER SEARCH TEST:
-- Press R, type search text, labels appear on TS nodes containing matches
-- Select a label → the entire TS node is selected (not just the text match)
--
-- OPERATOR-PENDING MODE:
--   dR → delete the node containing search text
--   yR → yank the node containing search text
--   cR → change the node containing search text
--
-- NORMAL/VISUAL MODE:
--   R → select the node containing search text

local function treesitter_search_demo()
	local config = {
		host = "localhost",
		port = 8080,
		debug = true,
	}
	-- Try: R then type "host" — labels appear on nodes containing "host"
	-- Select a label — the entire field (key = value) is selected

	local message = "Hello, " .. config.host .. ":" .. config.port
	-- Try: dR then type "Hello" — deletes the string assignment
	-- Try: yR then type "config" — yanks the table containing the match

	return message
end

local function another_search_target()
	local users = {
		{ name = "Alice", role = "admin" },
		{ name = "Bob", role = "user" },
		{ name = "Charlie", role = "user" },
	}
	-- Try: R then type "Alice" — select the node containing "Alice"
	-- Try: dR then type "Bob" — delete the entire table entry containing "Bob"

	for _, user in ipairs(users) do
		print(user.name .. " is " .. user.role)
	end
end

-- ── Section 8: Function text objects (af, if) ──────────────────

-- AROUND FUNCTION (af):
-- Try: vaf — labels on all functions, pick one → visually selects entire function
-- Try: daf — delete an entire function
-- Try: yaf — yank an entire function
-- Try: gqaf — format an entire function
-- Try: =af — auto-indent a function
-- Try: >af — indent a function

-- INSIDE FUNCTION (if):
-- Try: vif — labels on functions, pick one → selects only the body (no signature/end)
-- Try: dif — delete function body
-- Try: cif — change function body (enters insert mode)
-- Try: =if — auto-indent function body

local function short_function_one()
	return 42
end

local function short_function_two()
	return "hello"
end

local function multi_line_function(x, y)
	local sum = x + y
	local product = x * y
	if sum > product then
		return sum
	else
		return product
	end
end

local function another_multi_line(items)
	local filtered = {}
	for _, item in ipairs(items) do
		if item.active then
			filtered[#filtered + 1] = item
		end
	end
	return filtered
end

-- Try: vaf on short_function_one — should select from "local function" to "end"
-- Try: vif on multi_line_function — should select body only (inside the function)
-- Try: daf on short_function_two — should delete entire function
-- Try: cif on another_multi_line — should change the function body

-- ── Section 9: Class/struct text objects (ac, ic) ──────────────

-- AROUND CLASS (ac):
-- Try: vac — labels on class/module tables, pick one → visually selects entire table
-- Try: dac — delete an entire class
-- Try: yac — yank an entire class

-- INSIDE CLASS (ic):
-- Try: vic — selects only the body (inside the table braces)
-- Try: dic — delete class body
-- Try: cic — change class body

-- Note: Lua doesn't have native classes, but module tables match class_node_types.
-- For best results, test ac/ic in a JavaScript/TypeScript/Python file.

-- ── Section 10: Multi-char infer timing test ───────────────────

-- This section tests the f vs fn disambiguation.
-- The timeoutlen setting controls how long the system waits.
-- Default is usually 1000ms. Check with :set timeoutlen?
--
-- QUICK TYPING TEST:
--   1. Type dfn quickly (all 3 keys within timeoutlen) → should show function name labels
--   2. Type cfn quickly → should show function name labels, pick one → enters insert mode
--   3. Type yfn quickly → should show function name labels, pick one → yanks name
--
-- SLOW TYPING TEST:
--   1. Type d, then f, then WAIT more than timeoutlen → should resolve as find-char
--   2. The extractor will ask for 2 search characters (normal f behavior)
--
-- ESC TEST:
--   1. Type d, then f, then ESC during the wait → should resolve as find-char immediately

local function fn_timing_test_alpha()
	return "alpha"
end

local function fn_timing_test_beta()
	return "beta"
end

local function fn_timing_test_gamma()
	return "gamma"
end
