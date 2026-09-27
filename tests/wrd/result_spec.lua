local result = require("wrd.result")

describe("normalized results", function()
	it("filters locally while preserving original ranks and order", function()
		local entries = result.prepare({
			{ word = "curd", rank = 4, parts_of_speech = { "n" } },
			{ word = "cheesy", rank = 8, parts_of_speech = { "adj" } },
		})
		local nouns = result.filter_by_part_of_speech(entries, "noun")
		local adjectives = result.filter_by_part_of_speech(entries, "adj")

		assert.are.same(
			{ "curd" },
			vim.tbl_map(function(entry)
				return entry.word
			end, nouns)
		)
		assert.are.same(
			{ 4 },
			vim.tbl_map(function(entry)
				return entry.rank
			end, nouns)
		)
		assert.are.same(
			{ "cheesy" },
			vim.tbl_map(function(entry)
				return entry.word
			end, adjectives)
		)
	end)

	it("returns a new complete list for the all filter", function()
		local entries = result.prepare({ { word = "curd" } })
		local all = result.filter_by_part_of_speech(entries, "all")

		assert.are.same(entries, all)
		assert.are_not.equal(entries, all)
	end)

	it("assigns stable ranks and skips malformed records", function()
		local entries, issues, capabilities = result.prepare({
			{ word = "alpha", rank = 10 },
			{ word = "beta" },
			{ word = " ", rank = 3 },
			{ word = "gamma", rank = 10, definitions = { { part_of_speech = "v", text = " to test " } } },
		})

		assert.are.same(
			{ 10, 2, 4 },
			vim.tbl_map(function(entry)
				return entry.rank
			end, entries)
		)
		assert.are.same({ { index = 3, reason = "word must be a non-empty string" } }, issues)
		assert.is_true(capabilities.parts_of_speech)
		assert.are.same({ "verb" }, entries[3].parts_of_speech)
		assert.are.equal("to test", entries[3].definitions[1].text)
	end)
end)
