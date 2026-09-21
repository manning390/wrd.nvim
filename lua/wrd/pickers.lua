local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewer = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local wrd_actions = require("wrd.actions")
local entries = require("wrd.entries")
local picker_help = require("wrd.picker_help")
local picker_rank_jump = require("wrd.picker_rank_jump")
local picker_refinement = require("wrd.picker_refinement")
local preview = require("wrd.preview")

local M = {}
local preview_namespace = vim.api.nvim_create_namespace("wrd_preview")

function M.word_picker(data, prompt, opts)
	local highest_rank = 0
	for _, result in ipairs(data) do
		highest_rank = math.max(highest_rank, result.rank or 0)
	end

	local function make_entry(entry)
		if opts._wrd_normalized then
			return entries.make(entry, opts)
		end

		return vim.tbl_deep_extend("force", { wrd = { opts = opts } }, opts.client.entry_maker(entry))
	end

	local function preview_lines(entry)
		if opts._wrd_normalized then
			return preview.format_result(entry.value)
		end

		return preview.lines(opts.client.previewer(entry))
	end

	pickers
		.new(opts, {
			prompt_title = prompt,
			layout_strategy = "horizontal",
			sorting_strategy = "ascending",
			layout_config = {
				height = 0.9,
				width = 0.9,
				horizontal = { preview_width = 0.6 },
			},
			finder = finders.new_table({
				results = data,
				entry_maker = make_entry,
			}),
			sorter = conf.generic_sorter(opts),
			tiebreak = function(current_entry, existing_entry, current_prompt)
				if current_prompt == "" then
					return false
				end
				return conf.tiebreak(current_entry, existing_entry, current_prompt)
			end,
			previewer = previewer.new_buffer_previewer({
				define_preview = function(self, entry, _)
					vim.wo[self.state.winid].wrap = true
					local lines = preview_lines(entry)
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_clear_namespace(self.state.bufnr, preview_namespace, 0, -1)
					if opts._wrd_normalized then
						vim.api.nvim_buf_add_highlight(self.state.bufnr, preview_namespace, "Title", 0, 0, -1)
					end
				end,
				title = "Definition",
			}),
			attach_mappings = function(prompt_bufnr, map)
				local jump
				picker_help.attach(prompt_bufnr, opts)
				if opts._wrd_normalized then
					picker_refinement.attach(prompt_bufnr, data, make_entry)
					jump = picker_rank_jump.attach(
						prompt_bufnr,
						map,
						vim.tbl_extend("force", opts.rank_jump or {}, { max_rank = highest_rank })
					)
				end

				actions.select_default:replace(function(bufnr)
					if jump and jump.commit() then
						return
					end
					wrd_actions.wrd_select(bufnr)
				end)
				for mode, mode_mappings in pairs(opts.mappings or {}) do
					for key, action in pairs(mode_mappings) do
						map(mode, key, action)
					end
				end

				return true
			end,
		})
		:find()
end

function M.method_picker(available_methods, callback, opts)
	-- Make table
	local data = {}
	for i, k in ipairs(vim.tbl_keys(available_methods)) do
		data[i] = { value = k, ordinal = k, display = available_methods[k] }
	end
	-- Telescope picker
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
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry().value
					actions.close(prompt_bufnr)
					callback(selection)
				end)
				return true
			end,
		})
		:find()
end

return M
