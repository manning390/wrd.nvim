local preview = require("wrd.preview")

describe("preview line coercion", function()
	it("preserves a non-empty list of lines", function()
		local lines = { "first", "second" }

		assert.are.equal(lines, preview.lines(lines))
	end)

	it("splits a string into lines for legacy clients", function()
		assert.are.same({ "first", "second" }, preview.lines("first\nsecond"))
	end)

	it("shows a useful fallback for missing definitions", function()
		assert.are.same({ "No definition available." }, preview.lines(nil))
		assert.are.same({ "No definition available." }, preview.lines({}))
		assert.are.same({ "No definition available." }, preview.lines(""))
	end)

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
