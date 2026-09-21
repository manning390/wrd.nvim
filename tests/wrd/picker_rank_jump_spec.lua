local picker_rank_jump = require("wrd.picker_rank_jump")

describe("Telescope rank-jump mappings", function()
	it("feeds native Backspace when no numeric jump is pending", function()
		local mappings = {}
		local fed_backspace = false
		local original_feed_backspace = picker_rank_jump.feed_backspace
		picker_rank_jump.feed_backspace = function()
			fed_backspace = true
		end

		picker_rank_jump.attach(vim.api.nvim_get_current_buf(), function(mode, key, action)
			mappings[mode .. key] = action
		end, { max_rank = 100 })

		mappings["i<bs>"]()

		picker_rank_jump.feed_backspace = original_feed_backspace
		assert.is_true(fed_backspace)
	end)

	it("consumes Backspace when editing a pending numeric jump", function()
		local mappings = {}
		local fed_backspace = false
		local original_feed_backspace = picker_rank_jump.feed_backspace
		picker_rank_jump.feed_backspace = function()
			fed_backspace = true
		end

		local controller = picker_rank_jump.attach(vim.api.nvim_get_current_buf(), function(mode, key, action)
			mappings[mode .. key] = action
		end, { max_rank = 100 })
		controller.feed("1")
		mappings["i<bs>"]()

		picker_rank_jump.feed_backspace = original_feed_backspace
		assert.is_false(fed_backspace)
		assert.are.equal("", controller.pending())
	end)
end)
