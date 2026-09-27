local fzy = require("telescope.algos.fzy")
local entries = require("wrd.entries")

local M = {}

local function truncate(value, width)
	if vim.fn.strdisplaywidth(value) <= width then
		return value .. string.rep(" ", width - vim.fn.strdisplaywidth(value))
	end

	local suffix = "…"
	local available = math.max(1, width - vim.fn.strdisplaywidth(suffix))
	local text = ""
	for index = 0, vim.fn.strchars(value) - 1 do
		local candidate = text .. vim.fn.strcharpart(value, index, 1)
		if vim.fn.strdisplaywidth(candidate) > available then
			break
		end
		text = candidate
	end
	return text .. suffix
end

local function fuzzy_results(results, prompt)
	if prompt == "" then
		return vim.list_slice(results)
	end

	local query = prompt:lower()
	local matches = {}
	for index, result in ipairs(results) do
		local word = result.word:lower()
		if fzy.has_match(query, word) then
			table.insert(matches, { result = result, index = index, score = fzy.score(query, word) })
		end
	end
	table.sort(matches, function(left, right)
		if left.score == right.score then
			return left.index < right.index
		end
		return left.score > right.score
	end)

	return vim.tbl_map(function(match) return match.result end, matches)
end

function M.pack(results, columns)
	if #results == 0 then
		return {}
	end
	columns = math.max(1, math.min(columns, #results))
	local row_count = math.ceil(#results / columns)
	local rows = {}
	for row_index = 1, row_count do
		local row = { cells = {}, row = row_index }
		for column = 1, columns do
			row.cells[column] = results[(column - 1) * row_count + row_index]
		end
		table.insert(rows, row)
	end
	return rows
end

function M.new(results, opts, display_opts)
	opts = opts or {}
	local state = {
		_results = results,
		column = 1,
		columns = opts.columns or 5,
		cell_width = opts.cell_width or 18,
		separator = opts.separator or " │ ",
		display_opts = display_opts,
	}

	function state.set_results(values)
		state._results = values
	end

	function state.set_available_width(width)
		local separator_width = vim.fn.strdisplaywidth(state.separator)
		state.columns = math.max(1, math.min(opts.columns or 5, math.floor((width + separator_width) / (state.cell_width + separator_width))))
		state.column = math.min(state.column, state.columns)
		return state.columns
	end

	function state.rows(prompt)
		return M.pack(fuzzy_results(state._results, prompt or ""), state.columns)
	end

	function state.activate(entry, column, update_column)
		if not entry or not entry.wrd_grid then
			return nil
		end
		local cells = entry.wrd_grid.cells
		column = math.max(1, math.min(column or state.column, state.columns))
		while column > 1 and not cells[column] do
			column = column - 1
		end
		local result = cells[column]
		if not result then
			return nil
		end
		if update_column ~= false then
			state.column = column
		end
		entry.value = result
		entry.wrd = { word = result.word, rank = result.rank }
		return result
	end

	function state.display(row)
		local entry_display_opts = vim.tbl_deep_extend("force", {}, state.display_opts or {}, {
			picker = { show_part_of_speech = opts.show_part_of_speech == true },
		})
		local cells = {}
		for column = 1, state.columns do
			local result = row.cells[column]
			if result then
				local marker = column == state.column and "›" or " "
				cells[column] = marker .. truncate(entries.display(result, entry_display_opts), state.cell_width - 1)
			else
				cells[column] = string.rep(" ", state.cell_width)
			end
		end
		return table.concat(cells, state.separator)
	end

	function state.make_entry(row)
		local entry = {
			ordinal = table.concat(vim.tbl_map(function(result) return result and result.word or "" end, row.cells), " "),
			display = function() return state.display(row) end,
			wrd_grid = { cells = row.cells, state = state },
		}
		state.activate(entry, state.column, false)
		return entry
	end

	return state
end

return M
