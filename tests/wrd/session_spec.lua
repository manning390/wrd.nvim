local session = require("wrd.session")

describe("picker session", function()
	it("owns query context and creates fresh options for follow-up operations", function()
		local run_options
		local method_options
		local received_lifecycle
		local reopened_state
		local lifecycle = { restore = function() end }
		local target = { kind = "word", bufnr = 7 }
		local original = {
			word = "cheese",
			method = "means_like",
			target = target,
			client = { key = "fake" },
		}
		local state = session.new(original, {
			run = function(opts, transition)
				run_options = opts
				received_lifecycle = transition
			end,
			run_methods = function(opts, transition)
				method_options = opts
				received_lifecycle = transition
			end,
			reopen = function(state) reopened_state = state end,
		})

		assert.are.equal("cheese", state.query_word)
		assert.are.equal("means_like", state.method)
		assert.are.equal(target, state.target)

		state.follow("curd", lifecycle)
		assert.are.equal("curd", run_options.word)
		assert.are.equal("means_like", run_options.method)
		assert.are.equal("cheese", original.word)
		assert.are.equal(lifecycle, received_lifecycle)

		state.choose_method(lifecycle)
		assert.are.equal("cheese", method_options.word)
		assert.are.equal("", method_options.method)
		assert.are.equal(lifecycle, received_lifecycle)

		state.change_word("bread", lifecycle)
		assert.are.equal("bread", run_options.word)
		assert.are.equal(target, run_options.target)
		assert.are.equal(lifecycle, received_lifecycle)

		local snapshot = { prompt = "fuzzy", rank = 3 }
		state.reopen(snapshot)
		assert.are.equal(snapshot, reopened_state)
	end)

	it("does not expose its private base options through derived option tables", function()
		local state = session.new({ word = "cheese", method = "means_like" }, {})
		local derived = state.options()
		derived.word = "changed"

		assert.are.equal("cheese", state.options().word)
	end)
end)
