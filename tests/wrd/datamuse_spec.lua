local datamuse = require("wrd.clients.datamuse")

describe("Datamuse client", function()
	it("builds queries with metadata and an explicit result limit", function()
		assert.are.same({
			ml = "cheese",
			md = "dprf",
			max = 100,
		}, datamuse.build_query({ ml = "cheese" }))
	end)

	it("preserves explicit query overrides", function()
		local query = datamuse.build_query({ ml = "cheese", max = 25 })

		assert.are.equal(25, query.max)
	end)

	it("normalizes provider data into the public result contract", function()
		local lines = vim.fn.readfile("tests/fixtures/datamuse/cheese.json")
		local raw = vim.json.decode(table.concat(lines, "\n"))
		local entries = datamuse.normalize(raw)

		assert.are.equal(#raw, #entries)
		assert.are.equal(raw[1].word, entries[1].word)
		assert.are.same({ "adjective" }, entries[3].parts_of_speech)
		assert.are.same({
			part_of_speech = "noun",
			text = "(India) Dahi.",
		}, entries[4].definitions[2])
		assert.are.equal(raw[4], entries[4].raw)
	end)
end)
