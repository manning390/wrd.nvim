local client_contract = require("wrd.client")

describe("public client contract", function()
	local original_notify

	before_each(function()
		original_notify = vim.notify
	end)

	after_each(function()
		vim.notify = original_notify
	end)

	it("normalizes a non-Datamuse provider and infers optional capabilities", function()
		local client = {
			key = "dictionary",
			name = "Example Dictionary",
			available_methods = { define = "Define" },
			define = function(word)
				return { terms = { word } }
			end,
			normalize = function(response)
				return vim.tbl_map(function(word)
					return { word = word, definitions = { { text = "A custom definition." } } }
				end, response.terms)
			end,
		}

		local results, capabilities = client_contract.normalize(client, client.define("quark"))

		assert.are.equal("quark", results[1].word)
		assert.are.equal(1, results[1].rank)
		assert.are.equal("A custom definition.", results[1].definitions[1].text)
		assert.is_false(capabilities.parts_of_speech)
		assert.is_true(capabilities.rank_jump)
	end)

	it("reports malformed provider records with the client and index", function()
		local notification
		vim.notify = function(message, level)
			notification = { message, level }
		end
		local client = {
			key = "custom",
			available_methods = { lookup = "Lookup" },
			lookup = function()
				return {}
			end,
			normalize = function()
				return { { label = "missing word" } }
			end,
		}

		local results = client_contract.normalize(client, {})

		assert.are.same({}, results)
		assert.are.same({
			"Wrd: Client 'custom' skipped result #1: word must be a non-empty string",
			vim.log.levels.WARN,
		}, notification)
	end)

	it("rejects incomplete clients before querying", function()
		assert.has_error(function()
			client_contract.validate({ key = "old", available_methods = { lookup = "Lookup" } })
		end, "Wrd Error: Client 'old' must implement normalize(response)")
	end)

	it("rejects advertised methods that are not implemented", function()
		assert.has_error(function()
			client_contract.validate({
				key = "custom",
				available_methods = { lookup = "Lookup" },
				normalize = function()
					return {}
				end,
			})
		end, "Wrd Error: Client 'custom' does not implement method 'lookup'.")
	end)

	it("rejects unsupported capability declarations", function()
		assert.has_error(function()
			client_contract.validate({
				key = "custom",
				available_methods = { lookup = "Lookup" },
				lookup = function() end,
				normalize = function()
					return {}
				end,
				capabilities = { grid = true },
			})
		end, "Wrd Error: Client 'custom' advertises unsupported capability 'grid'")
	end)

	it("adds client context to provider normalization errors", function()
		local client = {
			key = "broken",
			available_methods = { lookup = "Lookup" },
			lookup = function()
				return {}
			end,
			normalize = function()
				error("bad response")
			end,
		}

		local ok, message = pcall(client_contract.normalize, client, {})
		assert.is_false(ok)
		assert.is_truthy(message:find("Wrd Error: Client 'broken' failed to normalize results", 1, true))
	end)

	it("infers and validates the optional exact-word description capability", function()
		local client = {
			key = "dictionary",
			available_methods = { lookup = "Lookup" },
			lookup = function()
				return {}
			end,
			normalize = function()
				return {}
			end,
			describe = function() end,
		}

		local _, capabilities = client_contract.normalize(client, {})
		assert.is_true(capabilities.describe)

		assert.has_error(function()
			client_contract.validate({
				key = "dictionary",
				available_methods = { lookup = "Lookup" },
				lookup = function()
					return {}
				end,
				normalize = function()
					return {}
				end,
				capabilities = { describe = true },
			})
		end, "Wrd Error: Client 'dictionary' advertises describe but does not implement it")
	end)

	it("normalizes only an exact description result", function()
		local client = { key = "dictionary" }
		local exact = client_contract.normalize_description(client, " Cheese ", {
			word = "cheese",
			definitions = { { part_of_speech = "n", text = "  Pressed milk curds. " } },
		})

		assert.are.equal("cheese", exact.word)
		assert.are.same({ { part_of_speech = "noun", text = "Pressed milk curds." } }, exact.definitions)
		assert.is_nil(client_contract.normalize_description(client, "cheese", { word = "cheesed" }))
	end)
end)
