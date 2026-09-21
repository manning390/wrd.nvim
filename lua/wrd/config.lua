local M = {}

local values

local function defaults()
	local actions = require("wrd.actions")

	return {
		client_key = "datamuse",
		default_method = "means_like",
		commands = true,
		rank_jump = {
			enabled = true,
			delay_ms = 600,
		},
		mappings = {
			i = {
				["<C-j>"] = actions.wrd_cycle_part_of_speech,
				["<C-y>"] = actions.wrd_copy,
				["<F1>"] = actions.wrd_help,
				["<tab>"] = actions.wrd_methods,
				["/"] = actions.wrd_follow,
			},
			n = {
				["<C-j>"] = actions.wrd_cycle_part_of_speech,
				["<C-y>"] = actions.wrd_copy,
				["<F1>"] = actions.wrd_help,
				["<tab>"] = actions.wrd_methods,
				["/"] = actions.wrd_follow,
			},
		},
	}
end

function M.setup(opts)
	values = vim.tbl_extend("keep", opts or {}, defaults())
	return values
end

function M.get()
	if not values then
		return M.setup()
	end

	return values
end

function M.is_setup()
	return values ~= nil
end

function M.defaults()
	return defaults()
end

return M
