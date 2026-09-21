return {
	setup = function()
		vim.api.nvim_create_user_command("Wrd", function(opts)
			local query = vim.fn.trim(opts.args)
			local target
			if opts.range > 0 then
				target = require("wrd.selection").line_target(
					vim.api.nvim_get_current_buf(),
					vim.api.nvim_get_current_win(),
					opts.line1,
					opts.line2
				)
			end
			require("wrd").run({ word = query, target = target })
		end, { nargs = "?", range = true, force = true })
	end,
}
