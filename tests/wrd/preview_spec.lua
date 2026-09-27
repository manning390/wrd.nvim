local preview = require("wrd.preview")

describe("normalized result previews", function()
	local function highlighted_text(lines, item)
		local line = lines[item.line + 1]
		if item.end_col == -1 then
			return line:sub(item.start_col + 1)
		end
		return line:sub(item.start_col + 1, item.end_col)
	end

	local function texts_for(lines, items, group)
		local texts = {}
		for _, item in ipairs(items) do
			if item.group == group then
				table.insert(texts, highlighted_text(lines, item))
			end
		end
		return texts
	end

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

	it("combines a limited query definition with the complete selected result", function()
		local lines = preview.format_picker({
			status = "ok",
			result = {
				word = "cheese",
				definitions = {
					{ part_of_speech = "noun", text = "Pressed milk curds." },
					{ text = "Something resembling cheese." },
				},
			},
		}, {
			word = "curd",
			rank = 5,
			definitions = { { part_of_speech = "noun", text = "Coagulated milk." } },
		}, { max_definitions = 1 })

		assert.are.same({
			"Query · cheese",
			"",
			"• [noun] Pressed milk curds.",
			"",
			"────────────────────────────",
			"",
			"Selected · curd · rank 5",
			"",
			"• [noun] Coagulated milk.",
		}, lines)
	end)

	it("shows loading context but hides unavailable query-definition outcomes", function()
		local selected = { word = "curd", rank = 5, definitions = {} }
		assert.are.same({
			"Query · cheese",
			"",
			"Loading definition…",
			"",
			"────────────────────────────",
			"",
			"Selected · curd · rank 5",
			"",
			preview.empty_message,
		}, preview.format_picker({ status = "loading", word = "cheese" }, selected))
		assert.are.same(preview.format_result(selected), preview.format_picker({ status = "empty" }, selected))
		assert.are.same(preview.format_result(selected), preview.format_picker({ status = "failed" }, selected))
	end)

	it("assigns semantic highlights to preview content", function()
		local lines = preview.format_picker({
			status = "ok",
			result = {
				word = "cheese",
				definitions = { { part_of_speech = "noun", text = "Pressed milk curds." } },
			},
		}, {
			word = "curd",
			rank = 5,
			definitions = { { part_of_speech = "noun", text = "Coagulated milk." } },
		})
		local highlights = preview.highlights(lines)

		assert.are.same({ "cheese", "curd" }, texts_for(lines, highlights, "WrdPreviewWord"))
		assert.are.same({ " · rank 5" }, texts_for(lines, highlights, "WrdPreviewRank"))
		assert.are.same({ "• ", "• " }, texts_for(lines, highlights, "WrdPreviewBullet"))
		assert.are.same({ "[noun]", "[noun]" }, texts_for(lines, highlights, "WrdPreviewPartOfSpeech"))
		assert.are.same(
			{ "Pressed milk curds.", "Coagulated milk." },
			texts_for(lines, highlights, "WrdPreviewDefinition")
		)
		assert.are.same(
			{ "────────────────────────────" },
			texts_for(lines, highlights, "WrdPreviewDivider")
		)
	end)

	it("highlights standalone words and unavailable-definition messages", function()
		local lines = preview.format_result({ word = "mystery", definitions = {} })
		local highlights = preview.highlights(lines)

		assert.are.same({ "mystery" }, texts_for(lines, highlights, "WrdPreviewWord"))
		assert.are.same({ preview.empty_message }, texts_for(lines, highlights, "WrdPreviewMuted"))
	end)
end)
