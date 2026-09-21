local refinement = require("wrd.refinement")

local entries = {
	{ word = "one", rank = 1, parts_of_speech = { "noun" } },
	{ word = "two", rank = 2, parts_of_speech = { "adjective", "noun" } },
	{ word = "three", rank = 3, parts_of_speech = { "verb" } },
	{ word = "four", rank = 4, parts_of_speech = { "adverb" } },
	{ word = "unknown", rank = 5, parts_of_speech = {} },
}

describe("part-of-speech refinement", function()
	it("cycles through all supported filters in a stable order", function()
		local current = "all"
		local visited = {}
		for _ = 1, 5 do
			current = refinement.next(current)
			table.insert(visited, current)
		end

		assert.are.same({ "noun", "adjective", "verb", "adverb", "all" }, visited)
	end)

	it("keeps untagged entries in All and excludes them from specific filters", function()
		assert.are.equal(5, #refinement.apply(entries, "all"))
		assert.are.equal(2, #refinement.apply(entries, "noun"))
		assert.are.equal(1, #refinement.apply(entries, "adjective"))
		assert.are.equal(1, #refinement.apply(entries, "verb"))
		assert.are.equal(1, #refinement.apply(entries, "adverb"))
	end)

	it("maintains picker-local filter state and original ranks", function()
		local state = refinement.new(entries)

		assert.are.equal("all", state.current())
		local nouns = state.cycle()
		assert.are.equal("noun", state.current())
		assert.are.same({ 1, 2 }, { nouns[1].rank, nouns[2].rank })
		assert.are.equal("Words · Nouns (2/5)", state.title())
	end)

	it("rejects unsupported filters without changing state", function()
		local state = refinement.new(entries)

		assert.is_nil(state.set("preposition"))
		assert.are.equal("all", state.current())
	end)

	it("skips unavailable filters while cycling", function()
		local state = refinement.new({
			{ word = "one", rank = 1, parts_of_speech = { "noun" } },
			{ word = "two", rank = 2, parts_of_speech = { "verb" } },
		})

		state.cycle()
		assert.are.equal("noun", state.current())
		state.cycle()
		assert.are.equal("verb", state.current())
		state.cycle()
		assert.are.equal("all", state.current())
	end)
end)
