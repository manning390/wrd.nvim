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

	it("builds an exact query-echo lookup for asynchronous descriptions", function()
		assert.are.same({
			sp = "cheese",
			qe = "sp",
			md = "dp",
			max = 1,
		}, datamuse.build_description_query("cheese"))
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

	it("returns only the exact normalized description candidate", function()
		local original_query_async = datamuse._query_async
		local received_query
		local received_error
		local received_result
		datamuse._query_async = function(query, callback)
			received_query = query
			callback(nil, {
				{ word = "cheesed", defs = { "v\tCovered with cheese." } },
				{ word = "cheese", defs = { "n\tPressed milk curds." } },
			})
		end

		datamuse.describe("Cheese", function(err, result)
			received_error = err
			received_result = result
		end)
		datamuse._query_async = original_query_async

		assert.are.equal("Cheese", received_query.sp)
		assert.is_nil(received_error)
		assert.are.equal("cheese", received_result.word)
		assert.are.equal("Pressed milk curds.", received_result.definitions[1].text)
	end)

	it("returns no description when Datamuse supplies only approximate matches", function()
		local original_query_async = datamuse._query_async
		local received_result = "unset"
		datamuse._query_async = function(_, callback)
			callback(nil, { { word = "cheesed", defs = { "v\tCovered with cheese." } } })
		end

		datamuse.describe("cheese", function(_, result) received_result = result end)
		datamuse._query_async = original_query_async

		assert.is_nil(received_result)
	end)
end)
