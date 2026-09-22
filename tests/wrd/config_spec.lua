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
end)
