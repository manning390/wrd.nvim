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

	it("exposes normalized results without changing the legacy result path", function()
		local lines = vim.fn.readfile("tests/fixtures/datamuse/cheese.json")
		local raw = vim.json.decode(table.concat(lines, "\n"))
		local entries = datamuse.normalize(raw)

		assert.are.equal(#raw, #entries)
		assert.are.equal(raw[1].word, datamuse.entry_maker(raw[1]).display)
		assert.are.equal(raw[1].word, entries[1].word)
	end)
end)
