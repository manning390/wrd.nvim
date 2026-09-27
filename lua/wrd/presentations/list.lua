local conf = require("telescope.config").values
local entries = require("wrd.entries")
local finders = require("telescope.finders")

local M = {}

function M.new(results, opts)
	local presentation = {}

	function presentation.layout(layout)
		return layout
	end

	function presentation.finder_for(values)
		return finders.new_table({
			results = values,
			entry_maker = function(result)
				return entries.make(result, opts)
			end,
		})
	end

	function presentation.finder()
		return presentation.finder_for(results)
	end

	function presentation.sorter()
		return conf.generic_sorter(opts)
	end

	function presentation.tiebreak(current_entry, existing_entry, prompt)
		if prompt == "" then
			return false
		end
		return conf.tiebreak(current_entry, existing_entry, prompt)
	end

	function presentation.activate(entry)
		return entry and entry.value
	end

	function presentation.attach(_, _, controller)
		controller.presentation = presentation
	end

	return presentation
end

return M
