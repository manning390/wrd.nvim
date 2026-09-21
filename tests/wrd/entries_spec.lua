local entries = require("wrd.entries")

describe("normalized Telescope entries", function()
	local result = {
		word = "parmesan",
		rank = 6,
		parts_of_speech = { "noun", "adjective" },
	}

	it("formats a compact rank, word, and part-of-speech display", function()
		assert.are.equal("  6. parmesan [n,adj]", entries.display(result))
	end)

	it("keeps only the word in the fuzzy-search ordinal", function()
		local opts = { method = "means_like", word = "cheese" }
		local entry = entries.make(result, opts)

		assert.are.equal(result, entry.value)
		assert.are.equal("parmesan", entry.ordinal)
		assert.are.equal("  6. parmesan [n,adj]", entry.display)
		assert.are.equal("parmesan", entry.wrd.word)
		assert.are.equal(6, entry.wrd.rank)
		assert.are.equal(opts, entry.wrd.opts)
	end)

	it("omits the label when part-of-speech metadata is unavailable", function()
		assert.are.equal(
			"100. mystery",
			entries.display({
				word = "mystery",
				rank = 100,
				parts_of_speech = {},
			})
		)
	end)
end)
