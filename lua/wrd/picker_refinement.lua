local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local refinement = require("wrd.refinement")

local M = {}

local function change_results_title(picker, title)
	picker.results_title = title
	if picker.layout and picker.layout.results and picker.layout.results.border then
		picker.layout.results.border:change_title(title)
	end
end

function M.attach(prompt_bufnr, entries, entry_maker)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local state = refinement.new(entries)

	local function refresh(filtered)
		picker:refresh(
			finders.new_table({
				results = filtered,
				entry_maker = entry_maker,
			}),
			{ reset_prompt = false }
		)
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

	picker._wrd_refinement = state
	change_results_title(picker, state.title())
	return state
end

return M
