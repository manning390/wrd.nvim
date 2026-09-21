local M = {}

M.empty_message = "No definition available."

function M.lines(value)
	if type(value) == "string" then
		if value == "" then
			return { M.empty_message }
		end
		return vim.split(value, "\n", { plain = true })
	end

	if type(value) == "table" and #value > 0 then
		return value
	end

	return { M.empty_message }
end

function M.format_result(result)
	local lines = { result.word .. ":", "" }

	if not result.definitions or #result.definitions == 0 then
		table.insert(lines, M.empty_message)
		return lines
	end

	for index, definition in ipairs(result.definitions) do
		local label = definition.part_of_speech and ("[" .. definition.part_of_speech .. "] ") or ""
		table.insert(lines, "• " .. label .. definition.text)
		if index < #result.definitions then
			table.insert(lines, "")
		end
	end

	return lines
end

return M
