local grid = require("wrd.grid")
local picker_grid = require("wrd.picker_grid")
local sorters = require("telescope.sorters")

local M = {}

function M.new(results, opts)
	local grid_opts = opts.picker.grid or {}
	local state = grid.new(results, grid_opts, opts)
	local presentation = { selection_strategy = "row" }

	function presentation.layout(layout)
		local configured = vim.deepcopy(layout)
		configured.layout_config.horizontal = configured.layout_config.horizontal or {}
		configured.layout_config.horizontal.preview_width = grid_opts.preview_width or 0.4
		return configured
	end

	function presentation.finder_for(values)
		state.set_results(values)
		return picker_grid.finder(state)
	end

	function presentation.finder()
		return presentation.finder_for(results)
	end

	function presentation.sorter()
		return sorters.empty()
	end

	function presentation.tiebreak()
		return false
	end

	function presentation.activate(entry)
		return state.activate(entry, state.column)
	end

	function presentation.attach(prompt_bufnr, map, controller)
		controller.presentation = presentation
		picker_grid.attach(prompt_bufnr, map, state, grid_opts, controller)
	end

	presentation.state = state
	return presentation
end

return M
