local saved_action_state
local saved_controller

describe("picker controller", function()
	local picker
	local controller

	before_each(function()
		saved_action_state = package.loaded["telescope.actions.state"]
		saved_controller = package.loaded["wrd.picker_controller"]
		picker = {}
		package.loaded["telescope.actions.state"] = {
			get_current_picker = function() return picker end,
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
end)
