local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewer = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local wrd_actions = require("wrd.actions")
local entries = require("wrd.entries")
local picker_help = require("wrd.picker_help")
local picker_grid = require("wrd.picker_grid")
local picker_rank_jump = require("wrd.picker_rank_jump")
local picker_refinement = require("wrd.picker_refinement")
local preview = require("wrd.preview")

local M = {}
local preview_namespace = vim.api.nvim_create_namespace("wrd_preview")

function M.word_layout(opts)
	local configured = (opts or {}).picker or {}
	return {
		layout_strategy = configured.layout_strategy or "horizontal",
		layout_config = configured.layout_config or {
			width = 0.95,
			height = 0.95,
			horizontal = { preview_width = 0.55, preview_cutoff = 100 },
		},
	}
end

function M.word_picker(data, prompt, opts)
	local layout = M.word_layout(opts)
	local grid_state
	if (opts.picker or {}).presentation == "grid" then
		local grid_opts = opts.picker.grid or {}
		grid_state = require("wrd.grid").new(data, grid_opts, opts)
		layout.layout_config = vim.deepcopy(layout.layout_config)
		layout.layout_config.horizontal = layout.layout_config.horizontal or {}
		layout.layout_config.horizontal.preview_width = grid_opts.preview_width or 0.4
	end
	local highest_rank = 0
	for _, result in ipairs(data) do
		highest_rank = math.max(highest_rank, result.rank or 0)
	end

	local function make_entry(entry)
		return entries.make(entry, opts)
	end

	local function preview_lines(entry)
		if grid_state then
			grid_state.activate(entry, grid_state.column)
		end
		return preview.format_result(entry.value)
	end

	local finder = grid_state and picker_grid.finder(grid_state) or finders.new_table({
		results = data,
		entry_maker = make_entry,
	})

	pickers
		.new(opts, {
			prompt_title = prompt,
			layout_strategy = layout.layout_strategy,
			sorting_strategy = "ascending",
			layout_config = layout.layout_config,
			finder = finder,
			sorter = grid_state and require("telescope.sorters").empty() or conf.generic_sorter(opts),
			selection_strategy = grid_state and "row" or nil,
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
					vim.api.nvim_buf_add_highlight(self.state.bufnr, preview_namespace, "Title", 0, 0, -1)
				end,
				title = "Definition",
			}),
			attach_mappings = function(prompt_bufnr, map)
				local jump
				picker_help.attach(prompt_bufnr, opts)
				if grid_state then
					picker_grid.attach(prompt_bufnr, map, grid_state, opts.picker.grid)
				end
				if (opts.capabilities or {}).parts_of_speech then
					picker_refinement.attach(prompt_bufnr, data, make_entry, grid_state and function(filtered)
						grid_state.set_results(filtered)
						return picker_grid.finder(grid_state)
					end or nil)
				end
				if (opts.capabilities or {}).rank_jump then
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
			attach_mappings = function(prompt_bufnr, map)
				picker_help.attach(prompt_bufnr, opts)
				actions.select_default:replace(function()
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
