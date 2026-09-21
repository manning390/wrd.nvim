local action_state = require("telescope.actions.state")
local rank_jump = require("wrd.rank_jump")

local M = {}

local function show_pending(value)
	if value == "" then
		vim.api.nvim_echo({ { "" } }, false, {})
	else
		vim.api.nvim_echo({ { "Wrd jump: " .. value .. "_", "ModeMsg" } }, false, {})
	end
end

function M.attach(prompt_bufnr, map, opts)
	opts = opts or {}
	if opts.enabled == false then
		return nil
	end

	local controller = rank_jump.new({
		delay_ms = opts.delay_ms,
		max_rank = opts.max_rank,
		on_change = show_pending,
		on_commit = function(rank)
			if not vim.api.nvim_buf_is_valid(prompt_bufnr) then
				return
			end

			local picker = action_state.get_current_picker(prompt_bufnr)
			if not rank_jump.select(picker, rank) then
				vim.notify(string.format("Wrd: Rank %d is not in the current results", rank), vim.log.levels.INFO)
			end
		end,
	})

	for digit = 0, 9 do
		local value = tostring(digit)
		local feed = function()
			controller.feed(value)
		end
		map("i", value, feed)
		map("n", value, feed)
	end

	return controller
end

return M
