local ok, actions = pcall(require, "telescope.actions")
if not ok then
	error("Wrd Error: This plugin requires nvim-telescope/telescope.nvim")
end

local action_state = require("telescope.actions.state")
local selection_target = require("wrd.selection")

local M = {}

function M.wrd_select(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	if not selection then
		return
	end
	local selected_word = selection.wrd.word

	selection_target.set_registers(selected_word)
	actions.close(prompt_bufnr)
	local applied, reason = selection_target.apply(selection.wrd.opts.target, selected_word)
	if not applied then
		vim.notify("Wrd: Copied selection; " .. reason, vim.log.levels.INFO)
	end
end

function M.wrd_copy(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	if not selection then
		return
	end

	selection_target.set_registers(selection.wrd.word)
	actions.close(prompt_bufnr)
end

function M.wrd_follow(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	if selection then
		local opts = vim.tbl_extend("force", selection.wrd.opts, { word = selection.wrd.word })
		actions.close(prompt_bufnr)
		require("wrd").run(opts)
	end
end

function M.wrd_methods(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	if selection then
		local opts = vim.tbl_extend("force", selection.wrd.opts, { method = "" })
		actions.close(prompt_bufnr)
		require("wrd").run_methods(opts)
	end
end

function M.wrd_change_word(prompt_bufnr)
	local selected = action_state.get_selected_entry()
	if not selected then
		return
	end

	local opts = vim.tbl_extend("force", {}, selected.wrd.opts)
	vim.ui.input({ prompt = "Wrd word: ", default = opts.word }, function(word)
		word = word and vim.fn.trim(word) or ""
		if word == "" or word == opts.word then
			return
		end

		if vim.api.nvim_buf_is_valid(prompt_bufnr) then
			actions.close(prompt_bufnr)
		end
		opts.word = word
		require("wrd").run(opts)
	end)
end

local function refine(prompt_bufnr, part_of_speech)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local refinement = picker and picker._wrd_refinement
	if not refinement then
		return
	end

	if part_of_speech then
		refinement.refresh(part_of_speech)
	else
		refinement.refresh_next()
	end
end

function M.wrd_cycle_part_of_speech(prompt_bufnr)
	refine(prompt_bufnr)
end

function M.wrd_filter_all(prompt_bufnr)
	refine(prompt_bufnr, "all")
end

function M.wrd_filter_nouns(prompt_bufnr)
	refine(prompt_bufnr, "noun")
end

function M.wrd_filter_adjectives(prompt_bufnr)
	refine(prompt_bufnr, "adjective")
end

function M.wrd_filter_verbs(prompt_bufnr)
	refine(prompt_bufnr, "verb")
end

function M.wrd_filter_adverbs(prompt_bufnr)
	refine(prompt_bufnr, "adverb")
end

function M.wrd_help(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	if picker and picker._wrd_help then
		picker._wrd_help.toggle()
	end
end

return M
