local preview = require("wrd.preview")

describe("normalized result previews", function()
	it("formats a normalized result like a definition popover", function()
		assert.are.same(
			{
				"curd:",
				"",
				"• [noun] The part of milk that coagulates.",
				"",
				"• [verb] (intransitive) To form curd; to curdle.",
			},
			preview.format_result({
				word = "curd",
				definitions = {
					{ part_of_speech = "noun", text = "The part of milk that coagulates." },
					{ part_of_speech = "verb", text = "(intransitive) To form curd; to curdle." },
				},
			})
		)
	end)

	it("includes the word heading when a normalized result has no definition", function()
		assert.are.same({
			"mystery:",
			"",
			"No definition available.",
		}, preview.format_result({ word = "mystery", definitions = {} }))
	end)
end)
