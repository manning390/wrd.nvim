local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")

local M = {}

function M.finder(state)
	return finders.new_dynamic({
		fn = function(prompt)
			return state.rows(prompt)
		end,
		entry_maker = function(row)
			return state.make_entry(row)
		end,
	})
end

function M.attach(prompt_bufnr, map, state, opts, controller)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local mappings = (opts or {}).mappings or {}
	state.set_available_width(vim.api.nvim_win_get_width(picker.results_win))
	local resize_group = vim.api.nvim_create_augroup("WrdGrid" .. prompt_bufnr, { clear = true })

	function state.refresh()
		picker:refresh(M.finder(state), { reset_prompt = false })
	end

	function state.move(delta)
		local entry = action_state.get_selected_entry()
		if not entry or not entry.wrd_grid then
			return false
		end
		local target = state.column + delta
		if target < 1 or target > state.columns or not entry.wrd_grid.cells[target] then
			return false
		end
		state.activate(entry, target)
		state.refresh()
		return true
	end

	local function bind(key, delta)
		if not key or key == false then
			return
		end
		map("i", key, function()
			state.move(delta)
		end)
		map("n", key, function()
			state.move(delta)
		end)
	end
	bind(mappings.left, -1)
	bind(mappings.right, 1)
	controller.grid = state

	vim.api.nvim_create_autocmd("VimResized", {
		group = resize_group,
		callback = function()
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(prompt_bufnr) or not vim.api.nvim_win_is_valid(picker.results_win) then
					return
				end
				local before = state.columns
				state.set_available_width(vim.api.nvim_win_get_width(picker.results_win))
				if before ~= state.columns then
					state.refresh()
				end
			end)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = resize_group,
		buffer = prompt_bufnr,
		once = true,
		callback = function()
			pcall(vim.api.nvim_del_augroup_by_id, resize_group)
		end,
	})
	return state
end

return M
