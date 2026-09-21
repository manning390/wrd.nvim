local function reload_wrd()
	for name in pairs(package.loaded) do
		if name == "wrd" or name:match("^wrd%.") then
			package.loaded[name] = nil
		end
	end

	return require("wrd")
end

describe("wrd public API", function()
	local original_notify

	before_each(function()
		original_notify = vim.notify
		pcall(vim.api.nvim_del_user_command, "Wrd")
	end)

	after_each(function()
		vim.notify = original_notify
		pcall(vim.api.nvim_del_user_command, "Wrd")
	end)

	it("registers the command by default and can be set up repeatedly", function()
		local wrd = reload_wrd()

		wrd.setup()
		wrd.setup()

		assert.are.equal(2, vim.fn.exists(":Wrd"))
	end)

	it("can disable command registration", function()
		local wrd = reload_wrd()

		wrd.setup({ commands = false })

		assert.are.equal(0, vim.fn.exists(":Wrd"))
	end)

	it("uses the configured client key", function()
		local wrd = reload_wrd()
		wrd.setup({ commands = false, client_key = "missing" })

		assert.has_error(function()
			wrd._make_client({})
		end, "Wrd Error: Client 'missing' is not available")
	end)

	it("dispatches supported client methods", function()
		local wrd = reload_wrd()
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function(word)
				return { word .. " result" }
			end,
		}

		assert.are.same({ "query result" }, wrd._fetch("query", "lookup", client))
	end)

	it("rejects unsupported client methods", function()
		local wrd = reload_wrd()
		local client = { key = "fake", available_methods = {} }

		assert.has_error(function()
			wrd._fetch("query", "missing", client)
		end, "Wrd Error: Method 'missing' is not available on Client 'fake'.")
	end)

	it("reports a genuinely empty result without opening a picker", function()
		local notification
		vim.notify = function(message, level)
			notification = { message = message, level = level }
		end
		local wrd = reload_wrd()
		local client = {
			key = "fake",
			available_methods = { synonym = "Synonym" },
			synonym = function()
				return {}
			end,
		}

		wrd.setup({ commands = false })
		local result = wrd.run({ word = "parmesan", method = "synonym", client = client })

		assert.is_nil(result)
		assert.are.same({
			message = "Wrd: No Synonym results for 'parmesan'",
			level = vim.log.levels.INFO,
		}, notification)
	end)
end)
