-- SmartMotion Playground: Treesitter Motions
-- Presets: ]], [[, ]c, [c, ]b, [b, daa, caa, yaa, dfn, cfn, yfn, saa, gS, R
--
-- INSTRUCTIONS:
--   ]]  → jump to next function definition
--   [[  → jump to previous function definition
--   ]c  → jump to next class/module table
--   [c  → jump to previous class/module table
--   ]b  → jump to next block/scope (if, for, while, pcall)
--   [b  → jump to previous block/scope
--   daa → delete around argument (pick an argument to delete, including comma)
--   caa → change around argument
--   yaa → yank around argument
--   dfn → delete function name
--   cfn → change function name
--   yfn → yank function name
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
    table.sort(results, function(a, b) return a.result > b.result end)
  end

  return results
end

-- Try: ]b from top — labels on if, for, while, pcall blocks
-- Try: [b from bottom — same in reverse

-- ── Section 4: Arguments for daa, caa, yaa, saa ──────────────

-- Try: daa near a function call — labels appear on arguments, delete one
-- Try: caa — same but enters insert mode after deleting
-- Try: yaa — yanks the argument (check :reg ")
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

-- ── Section 5: Function names for dfn, cfn, yfn ──────────────

-- Try: dfn — labels on function names, delete one
-- Try: cfn — labels on function names, change one (enters insert mode)
-- Try: yfn — labels on function names, yank one

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
  return text:gsub("[&<>\"]", entities)
end

local function unescape_html(text)
  local entities = { ["&amp;"] = "&", ["&lt;"] = "<", ["&gt;"] = ">", ["&quot;"] = '"' }
  return text:gsub("&%w+;", entities)
end

-- Try: dfn — labels appear on validate_email, validate_phone, validate_url, etc.
-- Try: cfn on validate_email — deletes the name, enters insert mode to type new one

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
