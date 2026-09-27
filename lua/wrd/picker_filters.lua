local action_state = require("telescope.actions.state")
local filters = require("wrd.filters")

local M = {}

local function change_results_title(picker, title)
	picker.results_title = title
	if picker.layout and picker.layout.results and picker.layout.results.border then
		picker.layout.results.border:change_title(title)
	end
end

function M.attach(prompt_bufnr, entries, finder_factory, controller, initial_filter)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local state = filters.new(entries)

	local function refresh(filtered)
		picker:refresh(finder_factory(filtered), { reset_prompt = false })
		change_results_title(picker, state.title())
	end

	function state.refresh(part_of_speech)
		local filtered = state.set(part_of_speech)
		if not filtered then
			return false
		end

		refresh(filtered)
		return true
	end

	function state.refresh_next()
		refresh(state.cycle())
		return true
	end

	controller.filters = state
	if initial_filter and initial_filter ~= "all" then
		state.refresh(initial_filter)
	else
		change_results_title(picker, state.title())
	end
	return state
end

return M
