-- SmartMotion Playground: Search Motions
-- Presets: s, S, f, F, t, T, ;, ,, gs, native /
--
-- INSTRUCTIONS:
--   s     → live search: type characters, labels narrow as you type (literal)
--   S     → fuzzy search: type partial patterns (e.g., "fn" matches "function")
--   f     → 2-char find AFTER cursor (type 2 chars, then pick label)
--   F     → 2-char find BEFORE cursor
--   t     → till char AFTER cursor (jumps one BEFORE the match)
--   T     → till char BEFORE cursor (jumps one AFTER the match)
--   ;     → repeat last f/F/t/T in same direction
--   ,     → repeat last f/F/t/T in opposite direction
--   gs    → visual range select: pick start word, pick end word → visual selection
--
-- NATIVE SEARCH:
--   /     → type pattern, labels appear incrementally as you type!
--   <C-s> → toggle SmartMotion labels on/off during search
--
-- LABEL CONFLICT AVOIDANCE:
--   When searching "fo" and matches include "foo", "for", "fox":
--   Labels "o", "r", "x" are excluded (they could be search continuations)
--
-- MULTI-WINDOW:
--   :vsplit tests/words_lines.lua
--   Press s or f — labels should appear in BOTH windows

-- ── Section 1: Repeated patterns for search ───────────────────

local function create_handler(name, callback)
  return {
    name = name,
    callback = callback,
    enabled = true,
    priority = 0,
  }
end

local function create_middleware(name, transform)
  return {
    name = name,
    transform = transform,
    enabled = true,
    priority = 0,
  }
end

local function create_validator(name, validate)
  return {
    name = name,
    validate = validate,
    enabled = true,
    priority = 0,
  }
end

-- Try: s then type "name" — multiple matches highlighted
-- Try: f then type "cr" — matches create_handler, create_middleware, create_validator
-- Try: t then type "e" — cursor lands just before the next "e"

-- ── Section 2: Varied vocabulary for f/F ──────────────────────

local database = {
  host = "localhost",
  port = 5432,
  username = "admin",
  password = "secret",
  database = "myapp_production",
  pool_size = 10,
  timeout = 30000,
  ssl_enabled = true,
  ssl_ca_cert = "/etc/ssl/certs/ca.pem",
  retry_count = 3,
  retry_delay = 1000,
}

local redis_config = {
  host = "127.0.0.1",
  port = 6379,
  prefix = "myapp:",
  ttl = 3600,
  max_memory = "256mb",
  eviction_policy = "allkeys-lru",
}

local elasticsearch = {
  nodes = { "http://es01:9200", "http://es02:9200", "http://es03:9200" },
  index_prefix = "logs-",
  bulk_size = 1000,
  flush_interval = 5,
  number_of_shards = 3,
  number_of_replicas = 1,
}

-- Try: f then "ho" — matches "host" in database, redis_config
-- Try: F then "po" — matches "port", "pool_size" going backward
-- Try: s then "ssl" — both ssl fields highlighted

-- ── Section 3: Prose-like content for gs ──────────────────────

-- Press gs here. Pick "quick" as start, "lazy" as end.
-- Result: visual selection spanning "quick brown fox jumps over the lazy"

local pangrams = {
  "the quick brown fox jumps over the lazy dog",
  "pack my box with five dozen liquor jugs",
  "how vexingly quick daft zebras jump",
  "the five boxing wizards jump quickly",
  "sphinx of black quartz judge my vow",
}

local lorem = [[
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.
]]

-- ── Section 4: t/T till targets ───────────────────────────────

-- Try: t then type "(" — cursor lands just before the parenthesis
-- Try: T then type ")" — cursor lands just after the parenthesis going backward
-- After t or T, press ; to repeat, , to reverse

local function parse_arguments(input_string)
  local args = {}
  local current = ""
  local depth = 0
  for i = 1, #input_string do
    local char = input_string:sub(i, i)
    if char == "(" then
      depth = depth + 1
      current = current .. char
    elseif char == ")" then
      depth = depth - 1
      current = current .. char
    elseif char == "," and depth == 0 then
      args[#args + 1] = current:match("^%s*(.-)%s*$")
      current = ""
    else
      current = current .. char
    end
  end
  if #current > 0 then
    args[#args + 1] = current:match("^%s*(.-)%s*$")
  end
  return args
end

local function build_query(table_name, conditions, order_by, limit)
  local query = "SELECT * FROM " .. table_name
  if conditions and #conditions > 0 then
    query = query .. " WHERE " .. table.concat(conditions, " AND ")
  end
  if order_by then
    query = query .. " ORDER BY " .. order_by
  end
  if limit then
    query = query .. " LIMIT " .. tostring(limit)
  end
  return query
end

local function format_duration(milliseconds)
  local seconds = math.floor(milliseconds / 1000)
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)
  seconds = seconds % 60
  minutes = minutes % 60
  if hours > 0 then
    return string.format("%dh %dm %ds", hours, minutes, seconds)
  elseif minutes > 0 then
    return string.format("%dm %ds", minutes, seconds)
  else
    return string.format("%ds", seconds)
  end
end

-- ── Section 5: ; and , repeat testing ─────────────────────────

-- REPEAT TEST:
-- 1. Place cursor at the start of this section
-- 2. Press f, type "lo" — jump to "local"
-- 3. Press ; — jump to next "lo" match (same direction)
-- 4. Press ; again — jump to the next one
-- 5. Press , — jump back to previous match (reversed direction)

local alpha = "first"
local bravo = "second"
local charlie = "third"
local delta = "fourth"
local echo = "fifth"
local foxtrot = "sixth"
local golf = "seventh"
local hotel = "eighth"
local india = "ninth"
local juliet = "tenth"

-- ── Section 6: Cross-window search ────────────────────────────

-- Open another file in a split:
--   :vsplit tests/operators.lua
-- Then press s and type "fun" — you should see labels in BOTH windows
-- Select a label from the other window to jump across

local function connect(host, port)
  print(string.format("Connecting to %s:%d", host, port))
  return { host = host, port = port, connected = true }
end

local function disconnect(connection)
  connection.connected = false
  print(string.format("Disconnected from %s:%d", connection.host, connection.port))
end

local function send_message(connection, message)
  if not connection.connected then
    error("Not connected")
  end
  print(string.format("Sending to %s: %s", connection.host, message))
end

local function receive_message(connection, timeout)
  if not connection.connected then
    error("Not connected")
  end
  timeout = timeout or 5000
  print(string.format("Waiting %dms for message from %s", timeout, connection.host))
  return "response"
end

-- ── Section 7: Fuzzy search with S ─────────────────────────────

-- FUZZY SEARCH TEST:
-- Press S (capital S) to start fuzzy search
-- Type partial patterns — they match non-consecutively:
--   "fn"  → matches "function", "firstName", "filename"
--   "cfg" → matches "config", "configure", "configuration"
--   "usr" → matches "user", "username", "userService"

local function createUserService(config)
  return {
    config = config,
    users = {},
    authenticate = function(self, username, password)
      return self.users[username] and self.users[username].password == password
    end,
  }
end

local function configureApplication(settings)
  local configuration = {
    debug = settings.debug or false,
    logLevel = settings.logLevel or "info",
    maxConnections = settings.maxConnections or 100,
  }
  return configuration
end

local function fetchUserProfile(userId)
  local firstName = "John"
  local lastName = "Doe"
  local userEmail = "john.doe@example.com"
  return {
    id = userId,
    firstName = firstName,
    lastName = lastName,
    email = userEmail,
  }
end

local function validateUsername(username)
  if not username or #username < 3 then
    return false, "Username too short"
  end
  if username:match("[^%w_]") then
    return false, "Username contains invalid characters"
  end
  return true
end

-- Try: S then "fn" — matches function, firstName
-- Try: S then "cfg" — matches config, configure, configuration
-- Try: S then "usr" — matches user, username, userService, userEmail
-- Try: S then "val" — matches validate, validateUsername, valid

-- SCORING TEST:
-- Fuzzy matches are sorted by score (best matches first)
-- Word boundary matches score higher than mid-word matches
-- Consecutive matches score higher than spread-out matches
