local query = require("wrd.query")

describe("wrd query orchestration", function()
	it("loads a configured built-in client", function()
		local opts = query.attach_client({}, { client_key = "datamuse" })

		assert.are.equal("datamuse", opts.client_key)
		assert.are.equal("datamuse", opts.client.key)
	end)

	it("preserves a per-call custom client", function()
		local client = { key = "custom" }
		local opts = query.attach_client({ client = client }, { client_key = "datamuse" })

		assert.are.equal(client, opts.client)
		assert.is_nil(opts.client_key)
	end)

	it("uses a custom client supplied through setup", function()
		local client = { key = "custom" }
		local opts = query.attach_client({}, { client = client, client_key = "configured" })

		assert.are.equal(client, opts.client)
		assert.are.equal("configured", opts.client_key)
	end)

	it("dispatches an advertised method", function()
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function(word)
				return word .. " result"
			end,
		}

		assert.are.equal("query result", query.fetch("query", "lookup", client))
	end)

	it("returns nil for a cancelled query", function()
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function()
				error("should not run")
			end,
		}

		assert.is_nil(query.fetch("", "lookup", client))
		assert.is_nil(query.fetch(nil, "lookup", client))
		assert.is_nil(query.fetch("query", nil, client))
	end)

	it("rejects unavailable and unimplemented methods", function()
		local client = {
			key = "fake",
			available_methods = { advertised = "Advertised" },
		}

		assert.has_error(function()
			query.fetch("query", "missing", client)
		end, "Wrd Error: Method 'missing' is not available on Client 'fake'.")

		assert.has_error(function()
			query.fetch("query", "advertised", client)
		end, "Wrd Error: Client 'fake' does not implement method 'advertised'.")
	end)
end)
