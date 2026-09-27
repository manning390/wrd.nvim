local saved_action_state
local saved_controller

describe("picker controller", function()
	local picker
	local controller
	local selected

	before_each(function()
		saved_action_state = package.loaded["telescope.actions.state"]
		saved_controller = package.loaded["wrd.picker_controller"]
		selected = nil
		picker = { _get_prompt = function() return "fuzzy" end }
		package.loaded["telescope.actions.state"] = {
			get_current_picker = function() return picker end,
			get_selected_entry = function() return selected end,
		}
		package.loaded["wrd.picker_controller"] = nil
		controller = require("wrd.picker_controller")
	end)

	after_each(function()
		package.loaded["telescope.actions.state"] = saved_action_state
		package.loaded["wrd.picker_controller"] = saved_controller
	end)

	it("attaches one Wrd state boundary to a Telescope picker", function()
		local session = { query_word = "cheese" }
		local state = controller.attach(42, session)

		assert.are.equal(state, picker._wrd)
		assert.are.equal(picker, state.picker)
		assert.are.equal(42, state.prompt_bufnr)
		assert.are.equal(session, state.session)
	end)

	it("retrieves the active picker controller", function()
		local state = controller.attach(42, {})

		assert.are.equal(state, controller.get(42))
	end)

	it("snapshots prompt, selection, filter, grid column, and input mode", function()
		selected = { wrd = { rank = 17 } }
		local state = controller.attach(42, {})
		state.filters = { current = function() return "noun" end }
		state.grid = { column = 3 }

		assert.are.same({
			prompt = "fuzzy",
			rank = 17,
			filter = "noun",
			column = 3,
			insert_mode = true,
		}, state.snapshot(true))
	end)
end)
