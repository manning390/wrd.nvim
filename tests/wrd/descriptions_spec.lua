local descriptions = require("wrd.descriptions")

describe("exact-word descriptions", function()
	before_each(function()
		descriptions.clear()
	end)

	it("reports unsupported clients without invoking transport", function()
		local outcome
		descriptions.request({ key = "plain" }, "cheese", function(value) outcome = value end)

		assert.are.equal("unsupported", outcome.status)
	end)

	it("normalizes exact results and caches them by client and word", function()
		local calls = 0
		local client = {
			key = "dictionary",
			describe = function(_, callback)
				calls = calls + 1
				callback(nil, { word = "cheese", definitions = { { text = "Pressed milk curds." } } })
			end,
		}
		local first
		local second

		descriptions.request(client, "Cheese", function(value) first = value end)
		descriptions.request(client, " cheese ", function(value) second = value end)

		assert.are.equal(1, calls)
		assert.are.equal("ok", first.status)
		assert.are.equal("Pressed milk curds.", first.result.definitions[1].text)
		assert.are.equal(first, second)
	end)

	it("coalesces concurrent lookups for the same client and word", function()
		local complete
		local calls = 0
		local outcomes = {}
		local client = {
			key = "dictionary",
			describe = function(_, callback)
				calls = calls + 1
				complete = callback
			end,
		}

		descriptions.request(client, "cheese", function(value) outcomes[1] = value end)
		descriptions.request(client, "cheese", function(value) outcomes[2] = value end)
		complete(nil, { word = "cheese", definitions = { { text = "Pressed milk curds." } } })

		assert.are.equal(1, calls)
		assert.are.equal("ok", outcomes[1].status)
		assert.are.equal(outcomes[1], outcomes[2])
	end)

	it("caches exact misses but retries failed lookups", function()
		local calls = 0
		local fail = false
		local client = {
			key = "dictionary",
			describe = function(_, callback)
				calls = calls + 1
				if fail then
					callback("offline")
				else
					callback(nil, { word = "cheesed" })
				end
			end,
		}
		local first
		local second

		descriptions.request(client, "cheese", function(value) first = value end)
		descriptions.request(client, "cheese", function(value) second = value end)
		assert.are.equal(1, calls)
		assert.are.equal("empty", first.status)
		assert.are.equal(first, second)

		descriptions.clear()
		fail = true
		descriptions.request(client, "cheese", function(value) first = value end)
		descriptions.request(client, "cheese", function(value) second = value end)
		assert.are.equal(3, calls)
		assert.are.equal("failed", first.status)
		assert.are.equal("failed", second.status)
	end)
end)
