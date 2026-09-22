local curl = require("plenary.curl")
local result = require("wrd.result")

local DATAMUSE_API_URL = "https://api.datamuse.com/words"

local Muse = {
	key = "datamuse",
	max_results = 100,
	available_methods = {
		means_like = "Means Like",
		sounds_like = "Sounds Like",
		spelled_like = "Spelled Like",
		synonym = "Synonym",
		antonym = "Antonym",
		popular_nouns = "Popular Nouns",
		popular_adjectives = "Popular Adjectives",
		generalize = "Generalize",
		compromise = "Compromise",
		homophones = "Homophones",
	},
	method_descriptions = {
		means_like = "words with a similar meaning",
		sounds_like = "words with a similar pronunciation",
		spelled_like = "words with a similar spelling",
		synonym = "direct synonyms",
		antonym = "words with an opposite meaning",
		popular_nouns = "frequently used nouns related to the query",
		popular_adjectives = "frequently used adjectives related to the query",
		generalize = "more general terms",
		compromise = "terms related to both sides of a phrase",
		homophones = "words pronounced the same way",
	},
}

local function parse_definition(value)
	if type(value) ~= "string" then
		return nil
	end

	local prefix, text = value:match("^([^\t]+)\t(.*)$")
	local part_of_speech = result.normalize_part_of_speech(prefix)
	if not part_of_speech then
		text = value
	end
	text = vim.trim(text)
	if text == "" then
		return nil
	end

	return { part_of_speech = part_of_speech, text = text }
end

function Muse.normalize(entries)
	local normalized = {}
	for _, entry in ipairs(entries or {}) do
		if type(entry) == "table" then
			local parts_of_speech = {}
			for _, tag in ipairs(entry.tags or {}) do
				local part = result.normalize_part_of_speech(tag)
				if part and not vim.tbl_contains(parts_of_speech, part) then
					table.insert(parts_of_speech, part)
				end
			end

			local definitions = {}
			for _, value in ipairs(entry.defs or {}) do
				local definition = parse_definition(value)
				if definition then
					table.insert(definitions, definition)
				end
			end

			table.insert(normalized, {
				word = entry.word,
				score = entry.score,
				parts_of_speech = parts_of_speech,
				definitions = definitions,
				raw = entry,
			})
		end
	end
	return normalized
end

function Muse.build_query(query)
	return vim.tbl_extend("keep", query, {
		md = "dprf", -- definition, parts of speech, pronunciation, and frequency
		max = Muse.max_results,
	})
end

function Muse._query(query)
	local resp = curl.get({
		url = DATAMUSE_API_URL,
		query = Muse.build_query(query),
		accept = "application/json",
	})

	if resp.exit ~= 0 then
		error(string.format("Wrd Error: Datamuse api call failed with status '%s'", resp.status))
	end

	local data = vim.fn.json_decode(resp.body)

	return data
end

function Muse.means_like(word)
	local query = { ml = word }
	return Muse._query(query)
end

function Muse.sounds_like(word)
	local query = { sl = word }
	return Muse._query(query)
end

function Muse.spelled_like(word)
	local query = { sp = word }
	return Muse._query(query)
end

function Muse._related(word, type)
	local query = { ["rel_" .. type] = word }
	return Muse._query(query)
end

function Muse.synonym(word)
	return Muse._related(word, "syn")
end

function Muse.antonym(word)
	return Muse._related(word, "ant")
end

function Muse.popular_nouns(word)
	return Muse._related(word, "jja")
end

function Muse.popular_adjectives(word)
	return Muse._related(word, "jjb")
end

function Muse.generalize(word)
	return Muse._related(word, "gen")
end

function Muse.compromise(word)
	return Muse._related(word, "com")
end

function Muse.homophones(word)
	return Muse._related(word, "hom")
end

return Muse
