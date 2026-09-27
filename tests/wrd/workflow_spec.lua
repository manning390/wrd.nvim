local config = require("wrd.config")
local pickers = require("wrd.pickers")
local workflow = require("wrd.workflow")

describe("wrd workflow transitions", function()
	local original_notify
	local original_word_picker
	local original_method_picker

	before_each(function()
		original_notify = vim.notify
		original_word_picker = pickers.word_picker
		original_method_picker = pickers.method_picker
		config.setup({ commands = false })
	end)

	after_each(function()
		vim.notify = original_notify
		pickers.word_picker = original_word_picker
		pickers.method_picker = original_method_picker
	end)

	it("restores the current picker when a replacement query fails", function()
		local restored = false
		local replaced = false
		local notification
		vim.notify = function(message, level) notification = { message, level } end
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function() error("offline") end,
			normalize = function(values) return values end,
		}

		workflow.new().run({ word = "cheese", method = "lookup", client = client, target = {} }, {
			before_open = function() replaced = true end,
			restore = function() restored = true end,
		})

		assert.is_true(restored)
		assert.is_false(replaced)
		assert.are.equal(vim.log.levels.ERROR, notification[2])
	end)

	it("replaces the current picker only after replacement results are ready", function()
		local events = {}
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function(word) return { { word = word .. "ish" } } end,
			normalize = function(values) return values end,
		}
		pickers.word_picker = function()
			table.insert(events, "open")
			return "opened"
		end

		local opened = workflow.new().run({ word = "green", method = "lookup", client = client, target = {} }, {
			before_open = function() table.insert(events, "close") end,
			restore = function() table.insert(events, "restore") end,
		})

		assert.are.equal("opened", opened)
		assert.are.same({ "close", "open" }, events)
	end)

	it("restores the current picker when replacement results are empty", function()
		local restored = false
		vim.notify = function() end
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function() return {} end,
			normalize = function(values) return values end,
		}

		workflow.new().run({ word = "missing", method = "lookup", client = client, target = {} }, {
			restore = function() restored = true end,
		})

		assert.is_true(restored)
	end)

	it("gives the method picker a restoration hook for cancellation", function()
		local received_on_close
		local restore = function() end
		local client = {
			key = "fake",
			available_methods = { lookup = "Lookup" },
			lookup = function() return {} end,
			normalize = function(values) return values end,
		}
		pickers.method_picker = function(_, _, _, on_close)
			received_on_close = on_close
		end

		workflow.new().methods({ word = "cheese", client = client, target = {} }, { restore = restore })

		assert.are.equal(restore, received_on_close)
	end)
end)
