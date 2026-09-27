local config

describe("wrd configuration", function()
	before_each(function()
		package.loaded["wrd.config"] = nil
		config = require("wrd.config")
	end)

	it("provides the documented defaults", function()
		local values = config.setup()

		assert.are.equal("datamuse", values.client_key)
		assert.are.equal("means_like", values.default_method)
		assert.is_true(values.commands)
		assert.is_true(values.rank_jump.enabled)
		assert.are.equal(600, values.rank_jump.delay_ms)
		assert.are.equal("horizontal", values.picker.layout_strategy)
		assert.are.equal("list", values.picker.presentation)
		assert.are.equal(0.95, values.picker.layout_config.width)
		assert.are.equal(0.95, values.picker.layout_config.height)
		assert.are.equal(0.55, values.picker.layout_config.horizontal.preview_width)
		assert.are.equal(100, values.picker.layout_config.horizontal.preview_cutoff)
		assert.is_true(values.picker.show_part_of_speech)
		assert.is_true(values.picker.query_definition.enabled)
		assert.are.equal(2, values.picker.query_definition.max_definitions)
		assert.are.equal(5, values.picker.grid.columns)
		assert.are.equal("<C-Left>", values.picker.grid.mappings.left)
		assert.are.equal("function", type(values.mappings.i["<C-e>"]))
		assert.are.equal("function", type(values.mappings.i["<C-j>"]))
		assert.are.equal("function", type(values.mappings.i["<C-y>"]))
		assert.are.equal("function", type(values.mappings.i["<F1>"]))
		assert.are.equal("function", type(values.mappings.i["<tab>"]))
		assert.are.equal("function", type(values.mappings.n["/"]))
	end)

	it("merges caller overrides without dropping unrelated default mappings", function()
		local mappings = { i = { x = function() end } }
		local values = config.setup({
			client_key = "custom",
			default_method = "lookup",
			commands = false,
			mappings = mappings,
		})

		assert.are.equal("custom", values.client_key)
		assert.are.equal("lookup", values.default_method)
		assert.is_false(values.commands)
		assert.are.equal(mappings.i.x, values.mappings.i.x)
		assert.are.equal("function", type(values.mappings.i["<F1>"]))
		assert.are.equal("function", type(values.mappings.n["<F1>"]))
	end)

	it("initializes lazily", function()
		assert.is_false(config.is_setup())

		local values = config.get()

		assert.is_true(config.is_setup())
		assert.are.equal("datamuse", values.client_key)
	end)

	it("returns fresh default tables", function()
		local first = config.defaults()
		first.mappings.i["/"] = nil
		first.rank_jump.enabled = false
		first.picker.layout_config.width = 0.5

		local second = config.defaults()

		assert.are.equal("function", type(second.mappings.i["/"]))
		assert.is_true(second.rank_jump.enabled)
		assert.are.equal(0.95, second.picker.layout_config.width)
	end)

	it("rejects invalid top-level and nested values with their configuration paths", function()
		assert.has_error(function()
			config.setup("invalid")
		end, "Wrd Error: config.setup must be a table (got string)")

		assert.has_error(function()
			config.setup({ rank_jump = { delay_ms = -1 } })
		end, "Wrd Error: config.rank_jump.delay_ms must be a non-negative number (got number)")

		assert.has_error(function()
			config.setup({ picker = { presentation = "columns" } })
		end, "Wrd Error: config.picker.presentation must be 'list' or 'grid' (got \"columns\")")

		assert.has_error(function()
			config.setup({ picker = { query_definition = { max_definitions = 0 } } })
		end, "Wrd Error: config.picker.query_definition.max_definitions must be a positive integer (got number)")
	end)

	it("retains the last valid configuration when a later setup call is invalid", function()
		local original = config.setup({ default_method = "sounds_like" })

		pcall(config.setup, { picker = { grid = { columns = 0 } } })

		assert.are.equal(original, config.get())
		assert.are.equal("sounds_like", config.get().default_method)
	end)

	it("allows mappings to be disabled without constraining Telescope action values", function()
		local custom_action = { type = "action_key", key = "select_default" }
		local values = config.setup({
			mappings = { i = { ["<C-y>"] = false, ["<C-k>"] = custom_action } },
			picker = { grid = { mappings = { left = false } } },
		})

		assert.is_false(values.mappings.i["<C-y>"])
		assert.are.equal(custom_action, values.mappings.i["<C-k>"])
		assert.is_false(values.picker.grid.mappings.left)
	end)
end)
