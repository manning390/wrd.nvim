local M = {}

local function is_digit(value)
	return type(value) == "string" and value:match("^%d$") ~= nil
end

function M.find_row(picker, rank)
	if not picker or not picker.manager then
		return nil
	end

	local index = 1
	for entry in picker.manager:iter() do
		if entry.wrd and entry.wrd.rank == rank then
			return picker:get_row(index)
		end
		index = index + 1
	end

	return nil
end

function M.select(picker, rank)
	local row = M.find_row(picker, rank)
	if row == nil then
		return false
	end

	picker:set_selection(row)
	return true
end

function M.new(opts)
	opts = opts or {}
	local delay_ms = opts.delay_ms or 600
	local max_rank = opts.max_rank or 100
	local max_digits = #tostring(max_rank)
	local schedule = opts.schedule or function(delay, callback)
		vim.defer_fn(callback, delay)
	end
	local on_change = opts.on_change or function() end
	local on_commit = opts.on_commit or function() end

	local pending = ""
	local generation = 0

	local function update(value)
		pending = value
		generation = generation + 1
		on_change(pending)
	end

	local controller = {}

	function controller.pending()
		return pending
	end

	function controller.cancel()
		if pending == "" then
			return false
		end

		update("")
		return true
	end

	function controller.backspace()
		if pending == "" then
			return false
		end

		update(pending:sub(1, -2))
		return true
	end

	function controller.commit()
		if pending == "" then
			return false
		end

		local rank = tonumber(pending)
		update("")
		on_commit(rank)
		return true
	end

	function controller.feed(digit)
		if not is_digit(digit) then
			return false
		end

		if pending == "" and digit == "0" then
			on_commit(0)
			return true
		end

		update(pending .. digit)
		local rank = tonumber(pending)
		if #pending >= max_digits or rank > max_rank or rank * 10 > max_rank then
			controller.commit()
			return true
		end

		local scheduled_generation = generation
		schedule(delay_ms, function()
			if pending ~= "" and generation == scheduled_generation then
				controller.commit()
			end
		end)
		return true
	end

	return controller
end

return M
