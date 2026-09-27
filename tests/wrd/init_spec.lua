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

	it("reports a genuinely empty result without opening a picker", function()
		local notification
		vim.notify = function(message, level)
			notification = { message = message, level = level }
		end
		local wrd = reload_wrd()
		local client = {
			key = "fake",
			available_methods = { synonym = "Synonym" },
			normalize = function(values) return values end,
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

	it("reports provider failures without treating them as empty results", function()
		local notification
		vim.notify = function(message, level)
			notification = { message = message, level = level }
		end
		local wrd = reload_wrd()
		local client = {
			key = "fake",
			available_methods = { synonym = "Synonym" },
			normalize = function(values) return values end,
			synonym = function() error("service unavailable") end,
		}

		wrd.setup({ commands = false })
		local result = wrd.run({ word = "parmesan", method = "synonym", client = client })

		assert.is_nil(result)
		assert.are.equal(vim.log.levels.ERROR, notification.level)
		assert.is_truthy(notification.message:find("Wrd: Client 'fake' method 'synonym' failed", 1, true))
		assert.is_truthy(notification.message:find("service unavailable", 1, true))
	end)

	it("passes a non-Datamuse client through the normalized picker boundary", function()
		local wrd = reload_wrd()
		local picker = require("wrd.pickers")
		local original_word_picker = picker.word_picker
		local received
		picker.word_picker = function(data, prompt, opts, picker_session)
			received = { data = data, prompt = prompt, opts = opts, session = picker_session }
			return "opened"
		end

		local client = {
			key = "dictionary",
			available_methods = { lookup = "Lookup" },
			lookup = function(word)
				return { records = { { term = word .. "ish", meaning = "Like " .. word } } }
			end,
			normalize = function(response)
				return vim.tbl_map(function(record)
					return {
						word = record.term,
						definitions = { { text = record.meaning } },
					}
				end, response.records)
			end,
		}

		wrd.setup({ commands = false })
		local opened = wrd.run({
			word = "green",
			method = "lookup",
			client = client,
			target = { kind = "insert", bufnr = 0, row = 1, col = 0 },
		})
		picker.word_picker = original_word_picker

		assert.are.equal("opened", opened)
		assert.are.equal("Lookup: green", received.prompt)
		assert.are.equal("greenish", received.data[1].word)
		assert.are.equal(1, received.data[1].rank)
		assert.are.equal("Like green", received.data[1].definitions[1].text)
		assert.is_false(received.opts.capabilities.parts_of_speech)
		assert.is_true(received.opts.capabilities.rank_jump)
		assert.are.equal("green", received.session.query_word)
		assert.are.equal("lookup", received.session.method)
		assert.are.equal(received.opts.target, received.session.target)
	end)

	it("routes method selection back through the same word-query workflow", function()
		local wrd = reload_wrd()
		local picker = require("wrd.pickers")
		local original_method_picker = picker.method_picker
		local original_word_picker = picker.word_picker
		local method_options
		local word_options
		local target = { kind = "word", bufnr = 7 }
		local client = {
			key = "dictionary",
			available_methods = { lookup = "Lookup" },
			lookup = function(word) return { { word = word .. "ish" } } end,
			normalize = function(values) return values end,
		}

		picker.method_picker = function(_, callback, opts)
			method_options = opts
			callback("lookup")
			return "methods-opened"
		end
		picker.word_picker = function(_, _, opts)
			word_options = opts
			return "words-opened"
		end

		wrd.setup({ commands = false })
		local opened = wrd.run_methods({ word = "green", client = client, target = target })
		picker.method_picker = original_method_picker
		picker.word_picker = original_word_picker

		assert.are.equal("methods-opened", opened)
		assert.are.equal(target, method_options.target)
		assert.are.equal("lookup", word_options.method)
		assert.are.equal("green", word_options.word)
		assert.are.equal(target, word_options.target)
	end)
end)
