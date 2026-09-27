describe("word picker construction", function()
	it("passes all 100 ranked results through the presentation boundary", function()
		local module_names = {
			"telescope.pickers",
			"telescope.previewers",
			"wrd.presentations",
			"wrd.pickers.word",
		}
		local original = {}
		for _, name in ipairs(module_names) do
			original[name] = package.loaded[name]
		end

		local presented
		local picker_spec
		local opened = false
		package.loaded["telescope.pickers"] = {
			new = function(_, spec)
				picker_spec = spec
				return {
					find = function()
						opened = true
					end,
					register_completion_callback = function() end,
				}
			end,
		}
		package.loaded["telescope.previewers"] = {
			new_buffer_previewer = function(spec)
				return spec
			end,
		}
		package.loaded["wrd.presentations"] = {
			new = function(results)
				presented = results
				return {
					layout = function(layout)
						return layout
					end,
					finder = function()
						return "ranked finder"
					end,
					sorter = function()
						return "word sorter"
					end,
					activate = function(entry)
						return entry.value
					end,
					attach = function() end,
				}
			end,
		}
		package.loaded["wrd.pickers.word"] = nil

		local results = {}
		for rank = 1, 100 do
			results[rank] = { word = "word" .. rank, rank = rank, definitions = {} }
		end
		local word_picker = require("wrd.pickers.word")
		word_picker.open(results, "Means Like: cheese", {
			picker = {},
			capabilities = {},
			mappings = {},
		}, {})

		for _, name in ipairs(module_names) do
			package.loaded[name] = original[name]
		end

		assert.are.equal(100, #presented)
		assert.are.equal(1, presented[1].rank)
		assert.are.equal(100, presented[100].rank)
		assert.are.equal("ranked finder", picker_spec.finder)
		assert.are.equal("word sorter", picker_spec.sorter)
		assert.is_true(opened)
	end)
end)
