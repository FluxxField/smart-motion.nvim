-- SmartMotion Playground: Word & Line Motions
-- Presets: w, b, e, ge, j, k
--
-- INSTRUCTIONS:
--   w  → labels on word starts AFTER cursor; pick one to jump
--   b  → labels on word starts BEFORE cursor
--   e  → labels on word ends AFTER cursor
--   ge → labels on word ends BEFORE cursor
--   j  → labels on lines BELOW cursor
--   k  → labels on lines ABOVE cursor
--
-- FLOW STATE: press w, select a target, then press w again quickly.
--   The second press should chain without labels if flow state is active.

-- ── Section 1: Variable declarations ──────────────────────────

local config = {
  timeout = 5000,
  retries = 3,
  backoff_factor = 1.5,
  max_connections = 100,
  enable_logging = true,
  log_level = "debug",
}

local http_status_codes = {
  OK = 200,
  CREATED = 201,
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  FORBIDDEN = 403,
  NOT_FOUND = 404,
  INTERNAL_SERVER_ERROR = 500,
  BAD_GATEWAY = 502,
  SERVICE_UNAVAILABLE = 503,
}

-- ── Section 2: String manipulation ────────────────────────────

local function slugify(text)
  local result = text:lower()
  result = result:gsub("[^%w%s-]", "")
  result = result:gsub("%s+", "-")
  result = result:gsub("%-+", "-")
  return result:match("^%-*(.-)%-*$")
end

local function truncate(str, max_len, suffix)
  suffix = suffix or "..."
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - #suffix) .. suffix
end

local function capitalize_words(sentence)
  return sentence:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

local function pad_right(str, width, char)
  char = char or " "
  if #str >= width then return str end
  return str .. char:rep(width - #str)
end

local function pad_left(str, width, char)
  char = char or " "
  if #str >= width then return str end
  return char:rep(width - #str) .. str
end

-- ── Section 3: Table utilities ────────────────────────────────

local function deep_clone(original)
  if type(original) ~= "table" then
    return original
  end
  local copy = {}
  for key, value in pairs(original) do
    copy[deep_clone(key)] = deep_clone(value)
  end
  return setmetatable(copy, getmetatable(original))
end

local function flatten(tbl, depth)
  depth = depth or math.huge
  local result = {}
  for _, value in ipairs(tbl) do
    if type(value) == "table" and depth > 0 then
      for _, inner in ipairs(flatten(value, depth - 1)) do
        result[#result + 1] = inner
      end
    else
      result[#result + 1] = value
    end
  end
  return result
end

local function group_by(tbl, key_fn)
  local groups = {}
  for _, item in ipairs(tbl) do
    local key = key_fn(item)
    if not groups[key] then
      groups[key] = {}
    end
    groups[key][#groups[key] + 1] = item
  end
  return groups
end

-- ── Section 4: Numeric computations ──────────────────────────

local function fibonacci(n)
  if n <= 1 then return n end
  local a, b = 0, 1
  for _ = 2, n do
    a, b = b, a + b
  end
  return b
end

local function is_prime(n)
  if n < 2 then return false end
  if n == 2 then return true end
  if n % 2 == 0 then return false end
  for i = 3, math.sqrt(n), 2 do
    if n % i == 0 then return false end
  end
  return true
end

local function clamp(value, min_val, max_val)
  return math.max(min_val, math.min(max_val, value))
end

local function lerp(a, b, t)
  return a + (b - a) * clamp(t, 0, 1)
end

local function map_range(value, in_min, in_max, out_min, out_max)
  return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)
end

-- ── Section 5: Iterator patterns ─────────────────────────────

local function filter(tbl, predicate)
  local result = {}
  for i, v in ipairs(tbl) do
    if predicate(v, i) then
      result[#result + 1] = v
    end
  end
  return result
end

local function map(tbl, transform)
  local result = {}
  for i, v in ipairs(tbl) do
    result[i] = transform(v, i)
  end
  return result
end

local function reduce(tbl, accumulator, initial)
  local acc = initial
  for i, v in ipairs(tbl) do
    acc = accumulator(acc, v, i)
  end
  return acc
end

local function zip(tbl_a, tbl_b)
  local result = {}
  local len = math.min(#tbl_a, #tbl_b)
  for i = 1, len do
    result[i] = { tbl_a[i], tbl_b[i] }
  end
  return result
end

-- ── Section 6: Usage ──────────────────────────────────────────

local names = { "alice", "bob", "charlie", "david", "eve", "frank", "grace" }
local scores = { 92, 85, 78, 95, 88, 72, 91 }

local paired = zip(names, scores)
local passing = filter(paired, function(pair) return pair[2] >= 80 end)
local formatted = map(passing, function(pair)
  return pad_right(capitalize_words(pair[1]), 10) .. " | " .. pad_left(tostring(pair[2]), 3)
end)

local total = reduce(scores, function(acc, v) return acc + v end, 0)
local average = total / #scores

print("Passing students:")
for _, line in ipairs(formatted) do
  print("  " .. line)
end
print(string.format("Average score: %.1f", average))

print("Fibonacci(20) = " .. fibonacci(20))
print("Primes under 50:")
for i = 2, 50 do
  if is_prime(i) then
    io.write(i .. " ")
  end
end
print()

local slug = slugify("Hello World! This is a Test String")
local truncated = truncate("The quick brown fox jumps over the lazy dog", 20)
print("Slug: " .. slug)
print("Truncated: " .. truncated)
