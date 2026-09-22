local M = {}

local part_of_speech_aliases = {
	n = "noun",
	N = "noun",
	noun = "noun",
	v = "verb",
	verb = "verb",
	adj = "adjective",
	adjective = "adjective",
	adv = "adverb",
	adverb = "adverb",
}

local function trim(value)
	return value:match("^%s*(.-)%s*$")
end

local function add_unique(values, seen, value)
	if value and not seen[value] then
		seen[value] = true
		table.insert(values, value)
	end
end

local function contains(values, target)
	for _, value in ipairs(values) do
		if value == target then
			return true
		end
	end

	return false
end

function M.normalize_part_of_speech(value)
	return part_of_speech_aliases[value]
end

function M.new(fields)
	assert(type(fields) == "table", "result fields must be a table")
	assert(type(fields.word) == "string" and fields.word ~= "", "result word must be a non-empty string")

	return {
		word = fields.word,
		rank = fields.rank,
		score = fields.score,
		parts_of_speech = fields.parts_of_speech or {},
		definitions = fields.definitions or {},
		provenance = fields.provenance,
		origin = fields.origin,
		concept = fields.concept,
		raw = fields.raw,
	}
end

local function normalize_definition(value)
	if type(value) ~= "table" or type(value.text) ~= "string" or trim(value.text) == "" then
		return nil
	end

	return {
		text = trim(value.text),
		part_of_speech = M.normalize_part_of_speech(value.part_of_speech),
		source = value.source,
	}
end

local function next_rank(preferred, used, fallback)
	if type(preferred) == "number" and preferred > 0 and preferred % 1 == 0 and not used[preferred] then
		used[preferred] = true
		return preferred
	end
	while used[fallback] do
		fallback = fallback + 1
	end
	used[fallback] = true
	return fallback
end

function M.prepare(values)
	local normalized = {}
	local issues = {}
	local used_ranks = {}
	local has_parts_of_speech = false

	for index, value in ipairs(values or {}) do
		if type(value) ~= "table" then
			table.insert(issues, { index = index, reason = "expected a result table" })
		elseif type(value.word) ~= "string" or trim(value.word) == "" then
			table.insert(issues, { index = index, reason = "word must be a non-empty string" })
		else
			local parts_of_speech = {}
			local seen_parts_of_speech = {}
			local supplied_parts = type(value.parts_of_speech) == "table" and value.parts_of_speech or {}
			for _, part in ipairs(supplied_parts) do
				add_unique(parts_of_speech, seen_parts_of_speech, M.normalize_part_of_speech(part))
			end

			local definitions = {}
			local supplied_definitions = type(value.definitions) == "table" and value.definitions or {}
			for _, definition in ipairs(supplied_definitions) do
				local item = normalize_definition(definition)
				if item then
					table.insert(definitions, item)
					add_unique(parts_of_speech, seen_parts_of_speech, item.part_of_speech)
				end
			end

			if #parts_of_speech > 0 then
				has_parts_of_speech = true
			end
			table.insert(normalized, M.new({
				word = trim(value.word),
				rank = next_rank(value.rank, used_ranks, index),
				score = value.score,
				parts_of_speech = parts_of_speech,
				definitions = definitions,
				provenance = value.provenance,
				origin = value.origin,
				concept = value.concept,
				raw = value.raw,
			}))
		end
	end

	return normalized, issues, { parts_of_speech = has_parts_of_speech }
end

function M.filter_by_part_of_speech(entries, part_of_speech)
	if not part_of_speech or part_of_speech == "all" then
		local copy = {}
		for _, entry in ipairs(entries or {}) do
			table.insert(copy, entry)
		end
		return copy
	end

	local normalized_part = M.normalize_part_of_speech(part_of_speech)
	if not normalized_part then
		return {}
	end

	local filtered = {}
	for _, entry in ipairs(entries or {}) do
		if contains(entry.parts_of_speech or {}, normalized_part) then
			table.insert(filtered, entry)
		end
	end

	return filtered
end

return M
