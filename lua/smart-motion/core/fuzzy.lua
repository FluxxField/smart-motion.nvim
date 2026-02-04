--- Fuzzy matching algorithm based on FZY.
--- Implements a dynamic programming approach for fuzzy string matching with scoring.
local M = {}

-- Scoring constants (based on FZY algorithm)
local SCORE_GAP_LEADING = -0.005
local SCORE_GAP_TRAILING = -0.005
local SCORE_GAP_INNER = -0.01
local SCORE_MATCH_CONSECUTIVE = 1.0
local SCORE_MATCH_SLASH = 0.9
local SCORE_MATCH_WORD = 0.8
local SCORE_MATCH_CAPITAL = 0.7
local SCORE_MATCH_DOT = 0.6
local SCORE_MAX = math.huge
local SCORE_MIN = -math.huge

--- Checks if a character is a word boundary.
---@param char string Single character
---@return boolean
local function is_boundary(char)
	return char == "/" or char == "-" or char == "_" or char == " " or char == "."
end

--- Checks if a character is uppercase.
---@param char string Single character
---@return boolean
local function is_upper(char)
	return char:match("[A-Z]") ~= nil
end

--- Checks if a character is lowercase.
---@param char string Single character
---@return boolean
local function is_lower(char)
	return char:match("[a-z]") ~= nil
end

--- Computes the bonus for a match at a given position.
---@param haystack string The string being searched
---@param i integer Position of the match (1-indexed)
---@return number Bonus score
local function compute_bonus(haystack, i)
	if i == 1 then
		-- First character gets word boundary bonus
		return SCORE_MATCH_WORD
	end

	local prev = haystack:sub(i - 1, i - 1)
	local curr = haystack:sub(i, i)

	if prev == "/" then
		return SCORE_MATCH_SLASH
	elseif prev == "-" or prev == "_" or prev == " " then
		return SCORE_MATCH_WORD
	elseif prev == "." then
		return SCORE_MATCH_DOT
	elseif is_lower(prev) and is_upper(curr) then
		-- CamelCase boundary
		return SCORE_MATCH_CAPITAL
	end

	return 0
end

--- Performs fuzzy matching of needle against haystack.
--- Returns the score and matched positions if there's a match.
---@param needle string The search pattern
---@param haystack string The string to search in
---@param case_sensitive boolean Whether to match case-sensitively
---@return number|nil score The match score (nil if no match)
---@return table|nil positions Array of matched character positions (1-indexed)
function M.match(needle, haystack, case_sensitive)
	local n = #needle
	local m = #haystack

	-- Empty needle matches everything with score 0
	if n == 0 then
		return 0, {}
	end

	-- Needle longer than haystack can't match
	if n > m then
		return nil, nil
	end

	-- Normalize case if not case-sensitive
	local needle_lower = case_sensitive and needle or needle:lower()
	local haystack_lower = case_sensitive and haystack or haystack:lower()

	-- Quick check: all needle chars must exist in haystack in order
	local j = 1
	for i = 1, n do
		local c = needle_lower:sub(i, i)
		local found = false
		while j <= m do
			if haystack_lower:sub(j, j) == c then
				found = true
				j = j + 1
				break
			end
			j = j + 1
		end
		if not found then
			return nil, nil
		end
	end

	-- Dynamic programming matrices
	-- D[i][j] = best score for matching needle[1..i] to haystack[1..j] ending with a match
	-- M[i][j] = best score for matching needle[1..i] to haystack[1..j]
	local D = {}
	local M_matrix = {}
	for i = 0, n do
		D[i] = {}
		M_matrix[i] = {}
		for k = 0, m do
			D[i][k] = SCORE_MIN
			M_matrix[i][k] = SCORE_MIN
		end
	end

	-- Base case: empty needle matches any prefix with leading gap penalty
	M_matrix[0][0] = 0
	for k = 1, m do
		M_matrix[0][k] = SCORE_GAP_LEADING * k
	end

	-- Fill the matrices
	for i = 1, n do
		local nc = needle_lower:sub(i, i)
		local prev_score = SCORE_MIN

		for k = 1, m do
			local hc = haystack_lower:sub(k, k)

			if nc == hc then
				-- Match!
				local bonus = compute_bonus(haystack, k)

				-- Score if this match is consecutive with previous
				local consecutive_score = D[i - 1][k - 1] + SCORE_MATCH_CONSECUTIVE

				-- Score if this match starts a new sequence
				local new_seq_score = M_matrix[i - 1][k - 1] + bonus

				D[i][k] = math.max(consecutive_score, new_seq_score)
			end

			-- Best score for needle[1..i] to haystack[1..j]:
			-- either we matched at position j (D[i][j])
			-- or we didn't match at j (M[i][j-1] + gap penalty)
			local gap_score = M_matrix[i][k - 1] + SCORE_GAP_INNER
			M_matrix[i][k] = math.max(D[i][k], gap_score)
		end
	end

	-- Find best score (with trailing gap penalty)
	local best_score = SCORE_MIN
	local best_end = m
	for k = n, m do
		local score = M_matrix[n][k] + SCORE_GAP_TRAILING * (m - k)
		if score > best_score then
			best_score = score
			best_end = k
		end
	end

	if best_score == SCORE_MIN then
		return nil, nil
	end

	-- Backtrack to find matched positions
	local positions = {}
	local i = n
	local k = best_end

	while i > 0 and k > 0 do
		if D[i][k] > SCORE_MIN and (D[i][k] >= M_matrix[i][k - 1] + SCORE_GAP_INNER or k == 1) then
			-- This position was a match
			table.insert(positions, 1, k)
			i = i - 1
			k = k - 1
		else
			k = k - 1
		end
	end

	return best_score, positions
end

--- Finds all fuzzy matches of needle in a line of text.
--- Returns matches with their positions, scores, and matched character indices.
---@param needle string The search pattern
---@param text string The line of text to search
---@param case_sensitive boolean Whether to match case-sensitively
---@return table[] Array of {start_col, end_col, score, positions}
function M.find_matches_in_line(needle, text, case_sensitive)
	local matches = {}
	local n = #needle
	local m = #text

	if n == 0 or m == 0 then
		return matches
	end

	-- For fuzzy matching, we look for word-like segments in the text
	-- and try to match the needle against each word/identifier
	local col = 1
	while col <= m do
		-- Find the start of a word (alphanumeric or identifier char)
		local word_start = text:find("[%w_]", col)
		if not word_start then
			break
		end

		-- Find the end of the word
		local word_end = word_start
		while word_end <= m and text:sub(word_end, word_end):match("[%w_]") do
			word_end = word_end + 1
		end
		word_end = word_end - 1

		local word = text:sub(word_start, word_end)
		local score, positions = M.match(needle, word, case_sensitive)

		if score then
			-- Adjust positions to be relative to the line, not the word
			local adjusted_positions = {}
			for _, pos in ipairs(positions) do
				table.insert(adjusted_positions, word_start + pos - 1)
			end

			table.insert(matches, {
				start_col = word_start - 1, -- 0-indexed
				end_col = word_end, -- 0-indexed, exclusive
				score = score,
				positions = adjusted_positions,
				text = word,
			})
		end

		col = word_end + 1
	end

	return matches
end

return M
