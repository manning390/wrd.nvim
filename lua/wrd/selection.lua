local M = {}

local keyword = vim.regex([=[\k\+]=])

local function ordered_positions(first, last)
	if first[1] < last[1] or (first[1] == last[1] and first[2] <= last[2]) then
		return first, last
	end
	return last, first
end

local function character_end(line, column)
	local remainder = line:sub(column + 1)
	local character = vim.fn.strcharpart(remainder, 0, 1)
	return column + #character
end

function M.word_bounds(line, cursor_column)
	local offset = 0
	while offset <= #line do
		local start_column, end_column = keyword:match_str(line:sub(offset + 1))
		if start_column == nil then
			return nil
		end

		start_column = start_column + offset
		end_column = end_column + offset
		if start_column <= cursor_column and cursor_column < end_column then
			return start_column, end_column
		end
		if start_column > cursor_column then
			return nil
		end
		offset = end_column
	end

	return nil
end

function M.visual_target(bufnr, winid, anchor, cursor, mode)
	local first, last = ordered_positions(anchor, cursor)
	local first_row = first[1] - 1
	local last_row = last[1] - 1

	if mode == "V" then
		return {
			bufnr = bufnr,
			winid = winid,
			kind = "line",
			start_row = first_row,
			start_col = 0,
			end_row = last_row + 1,
			end_col = 0,
		}
	end

	if mode == "\22" then
		return {
			bufnr = bufnr,
			winid = winid,
			kind = "block",
		}
	end

	local last_line = vim.api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, false)[1] or ""
	return {
		bufnr = bufnr,
		winid = winid,
		kind = "range",
		start_row = first_row,
		start_col = first[2] - 1,
		end_row = last_row,
		end_col = character_end(last_line, last[2] - 1),
	}
end

function M.line_target(bufnr, winid, first_line, last_line)
	return {
		bufnr = bufnr,
		winid = winid,
		kind = "line",
		start_row = first_line - 1,
		start_col = 0,
		end_row = last_line,
		end_col = 0,
	}
end

function M.capture()
	local bufnr = vim.api.nvim_get_current_buf()
	local winid = vim.api.nvim_get_current_win()
	local mode = vim.fn.mode()

	if mode == "v" or mode == "V" or mode == "\22" then
		local anchor = vim.fn.getpos("v")
		local cursor = vim.fn.getpos(".")
		return M.visual_target(bufnr, winid, { anchor[2], anchor[3] }, { cursor[2], cursor[3] }, mode)
	end

	local cursor = vim.api.nvim_win_get_cursor(winid)
	local row = cursor[1] - 1
	local column = cursor[2]
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local start_column, end_column = M.word_bounds(line, column)

	return {
		bufnr = bufnr,
		winid = winid,
		kind = start_column and "word" or "insert",
		start_row = row,
		start_col = start_column or column,
		end_row = row,
		end_col = end_column or column,
	}
end

function M.text(target)
	if not target or target.kind == "block" or not vim.api.nvim_buf_is_valid(target.bufnr) then
		return ""
	end

	if target.kind == "line" then
		return table.concat(vim.api.nvim_buf_get_lines(target.bufnr, target.start_row, target.end_row, false), " ")
	end

	return table.concat(
		vim.api.nvim_buf_get_text(target.bufnr, target.start_row, target.start_col, target.end_row, target.end_col, {}),
		" "
	)
end

function M.set_registers(text)
	for _, register in ipairs({ '"', "+", "*" }) do
		vim.fn.setreg(register, text, "v")
	end
end

function M.apply(target, text)
	if not target or target.kind == "block" then
		return false, target and "block selections are copy-only" or "no insertion target"
	end
	if not vim.api.nvim_buf_is_valid(target.bufnr) then
		return false, "the original buffer is no longer available"
	end
	if not vim.bo[target.bufnr].modifiable then
		return false, "the original buffer is not modifiable"
	end

	if target.kind == "line" then
		vim.api.nvim_buf_set_lines(target.bufnr, target.start_row, target.end_row, false, { text })
	else
		vim.api.nvim_buf_set_text(
			target.bufnr,
			target.start_row,
			target.start_col,
			target.end_row,
			target.end_col,
			{ text }
		)
	end

	if target.winid and vim.api.nvim_win_is_valid(target.winid) then
		local line_count = vim.api.nvim_buf_line_count(target.bufnr)
		local row = math.min(target.start_row + 1, line_count)
		local line = vim.api.nvim_buf_get_lines(target.bufnr, row - 1, row, false)[1] or ""
		vim.api.nvim_win_set_cursor(target.winid, { row, math.min(target.start_col + #text, #line) })
	end

	return true
end

return M
