local M = {}

M.empty_message = "No definition available."

M.highlight_links = {
	WrdPreviewHeading = "Title",
	WrdPreviewWord = "Identifier",
	WrdPreviewRank = "Number",
	WrdPreviewBullet = "Special",
	WrdPreviewPartOfSpeech = "Type",
	WrdPreviewDefinition = "Normal",
	WrdPreviewDivider = "WinSeparator",
	WrdPreviewMuted = "Comment",
}

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

local function append_definitions(lines, result, limit)
	if not result.definitions or #result.definitions == 0 then
		table.insert(lines, M.empty_message)
		return
	end
	for index, definition in ipairs(result.definitions) do
		if limit and index > limit then
			break
		end
		local label = definition.part_of_speech and ("[" .. definition.part_of_speech .. "] ") or ""
		table.insert(lines, "• " .. label .. definition.text)
		if index < #result.definitions and (not limit or index < limit) then
			table.insert(lines, "")
		end
	end
end

function M.format_picker(query_definition, selected, opts)
	if not query_definition or (query_definition.status ~= "loading" and query_definition.status ~= "ok") then
		return M.format_result(selected)
	end

	local query_word = query_definition.word or (query_definition.result and query_definition.result.word) or "Query"
	local lines = { "Query · " .. query_word, "" }
	if query_definition.status == "loading" then
		table.insert(lines, "Loading definition…")
	else
		append_definitions(lines, query_definition.result, (opts or {}).max_definitions)
	end

	table.insert(lines, "")
	table.insert(lines, "────────────────────────────")
	table.insert(lines, "")
	local selected_title = "Selected · " .. selected.word
	if selected.rank then
		selected_title = selected_title .. " · rank " .. selected.rank
	end
	table.insert(lines, selected_title)
	table.insert(lines, "")
	append_definitions(lines, selected)
	return lines
end

local function highlight(items, line, start_col, end_col, group)
	table.insert(items, {
		line = line,
		start_col = start_col,
		end_col = end_col,
		group = group,
	})
end

function M.highlights(lines)
	local items = {}
	for index, line in ipairs(lines) do
		local line_index = index - 1
		local heading_prefix
		if vim.startswith(line, "Query · ") then
			heading_prefix = "Query · "
		elseif vim.startswith(line, "Selected · ") then
			heading_prefix = "Selected · "
		end
		if heading_prefix then
			highlight(items, line_index, 0, -1, "WrdPreviewHeading")
			local rank_start = line:find(" · rank ", #heading_prefix + 1, true)
			local word_end = rank_start and (rank_start - 1) or #line
			highlight(items, line_index, #heading_prefix, word_end, "WrdPreviewWord")
			if rank_start then
				highlight(items, line_index, rank_start - 1, -1, "WrdPreviewRank")
			end
		elseif line == "────────────────────────────" then
			highlight(items, line_index, 0, -1, "WrdPreviewDivider")
		elseif line == "Loading definition…" or line == M.empty_message then
			highlight(items, line_index, 0, -1, "WrdPreviewMuted")
		elseif vim.startswith(line, "• ") then
			highlight(items, line_index, 0, #"• ", "WrdPreviewBullet")
			local part_start, part_end = line:find("^• %[[^%]]+%]")
			local definition_start = #"• "
			if part_start then
				highlight(items, line_index, #"• ", part_end, "WrdPreviewPartOfSpeech")
				definition_start = part_end + 1
			end
			highlight(items, line_index, definition_start, -1, "WrdPreviewDefinition")
		elseif line:sub(-1) == ":" then
			highlight(items, line_index, 0, #line - 1, "WrdPreviewWord")
		end
	end
	return items
end

function M.apply_highlights(bufnr, namespace, lines)
	for group, link in pairs(M.highlight_links) do
		vim.api.nvim_set_hl(0, group, { default = true, link = link })
	end
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
	for _, item in ipairs(M.highlights(lines)) do
		vim.api.nvim_buf_add_highlight(bufnr, namespace, item.group, item.line, item.start_col, item.end_col)
	end
end

return M
