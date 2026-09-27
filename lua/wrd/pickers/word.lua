local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local previewer = require("telescope.previewers")
local picker_help = require("wrd.picker_help")
local picker_controller = require("wrd.picker_controller")
local picker_rank_jump = require("wrd.picker_rank_jump")
local picker_filters = require("wrd.picker_filters")
local presentations = require("wrd.presentations")
local preview = require("wrd.preview")
local wrd_actions = require("wrd.actions")

local M = {}
local preview_namespace = vim.api.nvim_create_namespace("wrd_preview")

function M.layout(opts)
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

function M.open(data, prompt, opts, session)
	local presentation = presentations.new(data, opts)
	local layout = presentation.layout(M.layout(opts))
	local highest_rank = 0
	for _, result in ipairs(data) do
		highest_rank = math.max(highest_rank, result.rank or 0)
	end

	pickers
		.new(opts, {
			prompt_title = prompt,
			layout_strategy = layout.layout_strategy,
			sorting_strategy = "ascending",
			layout_config = layout.layout_config,
			finder = presentation.finder(),
			sorter = presentation.sorter(),
			selection_strategy = presentation.selection_strategy,
			tiebreak = presentation.tiebreak,
			previewer = previewer.new_buffer_previewer({
				define_preview = function(self, entry, _)
					vim.wo[self.state.winid].wrap = true
					local lines = preview.format_result(presentation.activate(entry))
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_clear_namespace(self.state.bufnr, preview_namespace, 0, -1)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, preview_namespace, "Title", 0, 0, -1)
				end,
				title = "Definition",
			}),
			attach_mappings = function(prompt_bufnr, map)
				local jump
				local controller = picker_controller.attach(prompt_bufnr, session)
				controller.results = data
				picker_help.attach(prompt_bufnr, opts, controller)
				presentation.attach(prompt_bufnr, map, controller)
				if (opts.capabilities or {}).parts_of_speech then
					picker_filters.attach(prompt_bufnr, data, presentation.finder_for, controller)
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

return M
