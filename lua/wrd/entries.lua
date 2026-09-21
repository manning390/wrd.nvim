local M = {}

local part_of_speech_labels = {
	noun = "n",
	verb = "v",
	adjective = "adj",
	adverb = "adv",
}

function M.part_of_speech_label(parts_of_speech)
	local labels = {}
	for _, part_of_speech in ipairs(parts_of_speech or {}) do
		local label = part_of_speech_labels[part_of_speech]
		if label then
			table.insert(labels, label)
		end
	end

	if #labels == 0 then
		return ""
	end

	return " [" .. table.concat(labels, ",") .. "]"
end

function M.display(result)
	return string.format("%3d. %s%s", result.rank, result.word, M.part_of_speech_label(result.parts_of_speech))
end

function M.make(result, opts)
	return {
		value = result,
		ordinal = result.word,
		display = M.display(result),
		wrd = {
			word = result.word,
			rank = result.rank,
			opts = opts,
		},
	}
end

return M
