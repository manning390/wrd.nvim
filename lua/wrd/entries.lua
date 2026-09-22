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

function M.display(result, opts)
	local show_part_of_speech = not opts or not opts.picker or opts.picker.show_part_of_speech ~= false
	local label = show_part_of_speech and M.part_of_speech_label(result.parts_of_speech) or ""
	return string.format("%3d. %s%s", result.rank, result.word, label)
end

function M.make(result, opts)
	return {
		value = result,
		ordinal = result.word,
		display = M.display(result, opts),
		wrd = {
			word = result.word,
			rank = result.rank,
			opts = opts,
		},
	}
end

return M
