local action_state = require("telescope.actions.state")
local help = require("wrd.help")
local help_window = require("wrd.help_window")

local M = {}

function M.attach(prompt_bufnr, opts)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local active_window
	local state = {}

	function state.toggle()
		if active_window and active_window.is_open() then
			active_window.close(true)
			active_window = nil
			return
		end

		local lines, close_keys = help.build(picker, opts)
		active_window = help_window.open(lines, {
			close_keys = close_keys,
			parent_bufnr = prompt_bufnr,
		})
	end

	picker._wrd_help = state
	return state
end

return M
