local action_state = require("telescope.actions.state")

local M = {}

function M.attach(prompt_bufnr, session)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local controller = {
		picker = picker,
		prompt_bufnr = prompt_bufnr,
		session = session,
	}

	function controller.restore_prompt(insert_mode)
		vim.schedule(function()
			local prompt_win = picker.prompt_win
			if not prompt_win or not vim.api.nvim_win_is_valid(prompt_win) or not vim.api.nvim_buf_is_valid(prompt_bufnr) then
				return
			end

			vim.api.nvim_set_current_win(prompt_win)
			if insert_mode then
				vim.cmd("startinsert")
			end
		end)
	end

	picker._wrd = controller
	return controller
end

function M.get(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	return picker and picker._wrd or nil
end

return M
