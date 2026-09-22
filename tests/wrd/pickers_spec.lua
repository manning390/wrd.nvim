local pickers = require("wrd.pickers")

describe("word picker layout", function()
	it("uses the dense side-by-side defaults", function()
		local layout = pickers.word_layout({})

		assert.are.equal("horizontal", layout.layout_strategy)
		assert.are.equal(0.95, layout.layout_config.width)
		assert.are.equal(0.95, layout.layout_config.height)
		assert.are.equal(0.55, layout.layout_config.horizontal.preview_width)
		assert.are.equal(100, layout.layout_config.horizontal.preview_cutoff)
	end)

	it("passes configured Telescope layout choices through unchanged", function()
		local configured = {
			layout_strategy = "vertical",
			layout_config = { width = 0.8, height = 0.7 },
		}
		local layout = pickers.word_layout({ picker = configured })

		assert.are.equal("vertical", layout.layout_strategy)
		assert.are.equal(configured.layout_config, layout.layout_config)
	end)
end)
