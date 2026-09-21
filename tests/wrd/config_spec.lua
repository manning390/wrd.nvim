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
		assert.are.equal("function", type(values.mappings.i["<C-j>"]))
		assert.are.equal("function", type(values.mappings.i["<C-y>"]))
		assert.are.equal("function", type(values.mappings.i["<F1>"]))
		assert.are.equal("function", type(values.mappings.i["<tab>"]))
		assert.are.equal("function", type(values.mappings.n["/"]))
	end)

	it("keeps caller overrides", function()
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
		assert.are.same(mappings, values.mappings)
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

		local second = config.defaults()

		assert.are.equal("function", type(second.mappings.i["/"]))
		assert.is_true(second.rank_jump.enabled)
	end)
end)
