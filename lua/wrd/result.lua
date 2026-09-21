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

function M.parse_definition(value)
	if type(value) ~= "string" then
		return nil
	end

	local prefix, text = value:match("^([^\t]+)\t(.*)$")
	local part_of_speech = M.normalize_part_of_speech(prefix)

	if not part_of_speech then
		text = value
	end

	text = trim(text)
	if text == "" then
		return nil
	end

	return {
		part_of_speech = part_of_speech,
		text = text,
	}
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
		raw = fields.raw,
	}
end

function M.from_datamuse(entry, rank)
	if type(entry) ~= "table" or type(entry.word) ~= "string" or entry.word == "" then
		return nil
	end

	local parts_of_speech = {}
	local seen_parts_of_speech = {}
	for _, tag in ipairs(entry.tags or {}) do
		add_unique(parts_of_speech, seen_parts_of_speech, M.normalize_part_of_speech(tag))
	end

	local definitions = {}
	for _, value in ipairs(entry.defs or {}) do
		local definition = M.parse_definition(value)
		if definition then
			table.insert(definitions, definition)
			add_unique(parts_of_speech, seen_parts_of_speech, definition.part_of_speech)
		end
	end

	return M.new({
		word = entry.word,
		rank = rank,
		score = entry.score,
		parts_of_speech = parts_of_speech,
		definitions = definitions,
		raw = entry,
	})
end

function M.normalize_datamuse(entries)
	local normalized = {}

	for rank, entry in ipairs(entries or {}) do
		local item = M.from_datamuse(entry, rank)
		if item then
			table.insert(normalized, item)
		end
	end

	return normalized
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
