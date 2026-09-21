local M = {}

local function dimensions(lines)
	local maximum = 0
	for _, line in ipairs(lines) do
		maximum = math.max(maximum, vim.fn.strdisplaywidth(line))
	end

	local width = math.max(1, math.min(math.max(maximum + 2, 50), vim.o.columns - 4))
	local height = math.max(1, math.min(#lines, vim.o.lines - 4))
	return {
		relative = "editor",
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " Wrd Help ",
		title_pos = "center",
		zindex = 100,
		focusable = false,
	}
end

function M.open(lines, opts)
	opts = opts or {}
	local origin_win = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_create_buf(false, true)
	local winid = vim.api.nvim_open_win(bufnr, false, dimensions(lines))
	local group = vim.api.nvim_create_augroup("WrdHelp" .. bufnr, { clear = true })
	local closed = false
	local window = { bufnr = bufnr, winid = winid }

	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].filetype = "wrd-help"
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.bo[bufnr].modifiable = false
	vim.wo[winid].wrap = false
	vim.wo[winid].cursorline = true

	function window.is_open()
		return not closed and vim.api.nvim_win_is_valid(winid)
	end

	function window.close(restore_focus)
		if closed then
			return
		end
		closed = true
		pcall(vim.api.nvim_del_augroup_by_id, group)
		if vim.api.nvim_win_is_valid(winid) then
			vim.api.nvim_win_close(winid, true)
		end
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
		if
			restore_focus ~= false
			and vim.api.nvim_win_is_valid(origin_win)
			and vim.api.nvim_get_current_win() ~= origin_win
		then
			vim.api.nvim_set_current_win(origin_win)
		end
	end

	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = function()
			if window.is_open() then
				vim.api.nvim_win_set_config(winid, dimensions(lines))
			end
		end,
	})
	if opts.parent_bufnr then
		vim.api.nvim_create_autocmd("BufWipeout", {
			group = group,
			buffer = opts.parent_bufnr,
			once = true,
			callback = function()
				window.close(false)
			end,
		})
	end

	return window
end

return M
