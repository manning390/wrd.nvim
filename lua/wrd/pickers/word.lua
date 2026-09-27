local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local previewer = require("telescope.previewers")
local picker_help = require("wrd.picker_help")
local picker_controller = require("wrd.picker_controller")
local picker_rank_jump = require("wrd.picker_rank_jump")
local picker_filters = require("wrd.picker_filters")
local presentations = require("wrd.presentations")
local preview = require("wrd.preview")
local rank_jump = require("wrd.rank_jump")
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

function M.open(data, prompt, opts, session, restore_state)
	local presentation = presentations.new(data, opts)
	if restore_state and restore_state.column and presentation.state then
		presentation.state.column = restore_state.column
	end
	local layout = presentation.layout(M.layout(opts))
	local highest_rank = 0
	for _, result in ipairs(data) do
		highest_rank = math.max(highest_rank, result.rank or 0)
	end

	local picker_opts = restore_state
			and vim.tbl_extend("force", {}, opts, {
				default_text = restore_state.prompt,
				initial_mode = restore_state.insert_mode and "insert" or "normal",
			})
		or opts
	local picker = pickers.new(picker_opts, {
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
				local lines = preview.format_picker(
					session.query_definition,
					presentation.activate(entry),
					(opts.picker or {}).query_definition
				)
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
				preview.apply_highlights(self.state.bufnr, preview_namespace, lines)
			end,
			title = "Definition",
		}),
		attach_mappings = function(prompt_bufnr, map)
			local jump
			local controller = picker_controller.attach(prompt_bufnr, session)
			controller.results = data
			session.on_query_definition(function()
				if vim.api.nvim_buf_is_valid(prompt_bufnr) then
					controller.picker:refresh_previewer()
				end
			end)
			picker_help.attach(prompt_bufnr, opts, controller)
			presentation.attach(prompt_bufnr, map, controller)
			if (opts.capabilities or {}).parts_of_speech then
				picker_filters.attach(
					prompt_bufnr,
					data,
					presentation.finder_for,
					controller,
					restore_state and restore_state.filter
				)
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
	if restore_state and restore_state.rank then
		picker:register_completion_callback(function(active_picker)
			rank_jump.select(active_picker, restore_state.rank)
		end)
	end
	picker:find()
end

return M
