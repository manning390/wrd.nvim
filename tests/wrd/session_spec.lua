local session = require("wrd.session")

describe("picker session", function()
	it("owns query context and creates fresh options for follow-up operations", function()
		local run_options
		local method_options
		local target = { kind = "word", bufnr = 7 }
		local original = {
			word = "cheese",
			method = "means_like",
			target = target,
			client = { key = "fake" },
		}
		local state = session.new(original, {
			run = function(opts) run_options = opts end,
			run_methods = function(opts) method_options = opts end,
		})

		assert.are.equal("cheese", state.query_word)
		assert.are.equal("means_like", state.method)
		assert.are.equal(target, state.target)

		state.follow("curd")
		assert.are.equal("curd", run_options.word)
		assert.are.equal("means_like", run_options.method)
		assert.are.equal("cheese", original.word)

		state.choose_method()
		assert.are.equal("cheese", method_options.word)
		assert.are.equal("", method_options.method)

		state.change_word("bread")
		assert.are.equal("bread", run_options.word)
		assert.are.equal(target, run_options.target)
	end)

	it("does not expose its private base options through derived option tables", function()
		local state = session.new({ word = "cheese", method = "means_like" }, {})
		local derived = state.options()
		derived.word = "changed"

		assert.are.equal("cheese", state.options().word)
	end)
end)
