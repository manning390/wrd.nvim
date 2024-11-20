local ok, actions = pcall(require, "telescope.actions")
if not ok then
	error("Wrd Error: This plugin requires nvim-telescope/telescope.nvim")
end

local action_state = require("telescope.actions.state")

local M = {}

function M.wrd_select(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	local selected_word = selection.wrd.word

	vim.fn.setreg("*", selected_word)
	vim.fn.setreg("@", selected_word)
	if vim.fn.expand("<cword>") ~= "" then
		vim.cmd("norm diw")
		vim.api.nvim_put({ selected_word }, "", false, true)
	end

	actions.close(prompt_bufnr)
end

function M.wrd_follow(_)
	local selection = action_state.get_selected_entry()
	if selection then
		require("wrd").run(vim.tbl_extend("keep", { word = selection.wrd.word }, selection.wrd.opts))
	end
end

function M.wrd_methods(_)
	local selection = action_state.get_selected_entry()
	if selection then
		require("wrd").run_methods(vim.tbl_extend("keep", { method = "" }, selection.wrd.opts))
	end
end

return M
