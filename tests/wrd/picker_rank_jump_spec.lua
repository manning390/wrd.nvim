local picker_rank_jump = require("wrd.picker_rank_jump")

describe("Telescope rank-jump mappings", function()
	it("does not override native Backspace or Escape behavior", function()
		local mappings = {}

		picker_rank_jump.attach(vim.api.nvim_get_current_buf(), function(mode, key, action)
			mappings[mode .. key] = action
		end, { max_rank = 100 })

		assert.is_nil(mappings["i<bs>"])
		assert.is_nil(mappings["i<esc>"])
		assert.is_nil(mappings["n<esc>"])
	end)
end)
