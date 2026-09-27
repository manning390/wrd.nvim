local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local conf = require("telescope.config").values
local finders = require("telescope.finders")
local picker_help = require("wrd.picker_help")
local picker_controller = require("wrd.picker_controller")
local pickers = require("telescope.pickers")
local wrd_actions = require("wrd.actions")

local M = {}

function M.open(available_methods, callback, opts, on_close)
	local data = {}
	for index, method in ipairs(vim.tbl_keys(available_methods)) do
		data[index] = { value = method, ordinal = method, display = available_methods[method] }
	end

	pickers
		.new(opts, {
			prompt_title = opts.prompt_title,
			finder = finders.new_table({
				results = data,
				entry_maker = function(entry)
					return entry
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				local selected = false
				local controller = picker_controller.attach(prompt_bufnr)
				controller.methods = data
				if on_close then
					vim.api.nvim_create_autocmd("BufWipeout", {
						buffer = prompt_bufnr,
						once = true,
						callback = function()
							vim.schedule(function()
								if not selected then
									on_close()
								end
							end)
						end,
					})
				end
				picker_help.attach(prompt_bufnr, opts, controller)
				actions.select_default:replace(function()
					selected = true
					local selection = action_state.get_selected_entry().value
					actions.close(prompt_bufnr)
					callback(selection)
				end)
				for mode, mode_mappings in pairs(opts.mappings or {}) do
					for key, action in pairs(mode_mappings) do
						if action == wrd_actions.wrd_help then
							map(mode, key, action)
						end
					end
				end
				return true
			end,
		})
		:find()
end

return M
