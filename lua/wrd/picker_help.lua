local help = require("wrd.help")
local help_window = require("wrd.help_window")

local M = {}

function M.attach(prompt_bufnr, opts, controller)
	local picker = controller.picker
	local active_window
	local state = {}

	function state.toggle()
		if active_window and active_window.is_open() then
			active_window.close(true)
			active_window = nil
			return
		end

		local lines = help.build(picker, opts)
		active_window = help_window.open(lines, {
			parent_bufnr = prompt_bufnr,
		})
	end

	controller.help = state
	return state
end

return M
