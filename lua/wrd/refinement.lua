local result = require("wrd.result")

local M = {}

M.filters = { "all", "noun", "adjective", "verb", "adverb" }

local labels = {
	all = "All",
	noun = "Nouns",
	adjective = "Adjectives",
	verb = "Verbs",
	adverb = "Adverbs",
}

function M.label(part_of_speech)
	return labels[part_of_speech]
end

function M.next(part_of_speech)
	for index, value in ipairs(M.filters) do
		if value == part_of_speech then
			return M.filters[(index % #M.filters) + 1]
		end
	end

	return M.filters[1]
end

function M.apply(entries, part_of_speech)
	return result.filter_by_part_of_speech(entries, part_of_speech)
end

function M.title(part_of_speech, eligible_count, total_count)
	return string.format("Words · %s (%d/%d)", labels[part_of_speech] or part_of_speech, eligible_count, total_count)
end

function M.new(entries)
	local source = entries or {}
	local current = "all"
	local state = {}

	function state.current()
		return current
	end

	function state.set(part_of_speech)
		if not labels[part_of_speech] then
			return nil
		end

		current = part_of_speech
		return M.apply(source, current)
	end

	function state.cycle()
		local candidate = current
		for _ = 1, #M.filters do
			candidate = M.next(candidate)
			local filtered = M.apply(source, candidate)
			if #filtered > 0 then
				current = candidate
				return filtered
			end
		end

		return state.results()
	end

	function state.results()
		return M.apply(source, current)
	end

	function state.title()
		local filtered = state.results()
		return M.title(current, #filtered, #source)
	end

	return state
end

return M
