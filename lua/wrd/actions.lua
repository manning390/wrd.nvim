local ok, actions = pcall(require, "telescope.actions")
if not ok then
	error("Wrd Error: This plugin requires nvim-telescope/telescope.nvim")
end

local action_state = require("telescope.actions.state")
local picker_controller = require("wrd.picker_controller")
local selection_target = require("wrd.selection")

local M = {}

function M.wrd_select(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	if not selection then
		return
	end
	local selected_word = selection.wrd.word
	local controller = picker_controller.get(prompt_bufnr)
	local session = controller and controller.session

	selection_target.set_registers(selected_word)
	actions.close(prompt_bufnr)
	local applied, reason = selection_target.apply(session and session.target, selected_word)
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
	local controller = picker_controller.get(prompt_bufnr)
	local session = controller and controller.session
	if selection and session then
		actions.close(prompt_bufnr)
		session.follow(selection.wrd.word)
	end
end

function M.wrd_methods(prompt_bufnr)
	local controller = picker_controller.get(prompt_bufnr)
	local session = controller and controller.session
	if session then
		actions.close(prompt_bufnr)
		session.choose_method()
	end
end

function M.wrd_change_word(prompt_bufnr)
	local controller = picker_controller.get(prompt_bufnr)
	local session = controller and controller.session
	if not session then
		return
	end
	local return_to_insert = vim.api.nvim_get_mode().mode:sub(1, 1) == "i"

	vim.ui.input({ prompt = "Wrd word: ", default = session.query_word }, function(word)
		word = word and vim.fn.trim(word) or ""
		if word == "" or word == session.query_word then
			controller.restore_prompt(return_to_insert)
			return
		end

		if vim.api.nvim_buf_is_valid(prompt_bufnr) then
			actions.close(prompt_bufnr)
		end
		session.change_word(word)
	end)
end

local function apply_filter(prompt_bufnr, part_of_speech)
	local controller = picker_controller.get(prompt_bufnr)
	local filters = controller and controller.filters
	if not filters then
		return
	end

	if part_of_speech then
		filters.refresh(part_of_speech)
	else
		filters.refresh_next()
	end
end

function M.wrd_cycle_part_of_speech(prompt_bufnr)
	apply_filter(prompt_bufnr)
end

function M.wrd_filter_all(prompt_bufnr)
	apply_filter(prompt_bufnr, "all")
end

function M.wrd_filter_nouns(prompt_bufnr)
	apply_filter(prompt_bufnr, "noun")
end

function M.wrd_filter_adjectives(prompt_bufnr)
	apply_filter(prompt_bufnr, "adjective")
end

function M.wrd_filter_verbs(prompt_bufnr)
	apply_filter(prompt_bufnr, "verb")
end

function M.wrd_filter_adverbs(prompt_bufnr)
	apply_filter(prompt_bufnr, "adverb")
end

function M.wrd_help(prompt_bufnr)
	local controller = picker_controller.get(prompt_bufnr)
	if controller and controller.help then
		controller.help.toggle()
	end
end

return M
