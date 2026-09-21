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

function Muse.entry_maker(entry)
	return {
		value = entry,
		ordinal = entry.word,
		display = entry.word,
		wrd = { word = entry.word },
	}
end

function Muse.previewer(entry)
	return entry.value.defs
end

function Muse.normalize(entries)
	return result.normalize_datamuse(entries)
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
