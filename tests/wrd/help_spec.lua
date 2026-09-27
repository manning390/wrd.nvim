local actions = require("wrd.actions")
local help = require("wrd.help")

local function contains(lines, pattern)
	for _, line in ipairs(lines) do
		if line:find(pattern, 1, true) then
			return true
		end
	end
	return false
end

describe("help model", function()
	it("describes active context and effective Wrd mappings", function()
		local picker = {
			_wrd = { filters = {
				current = function()
					return "noun"
				end,
			} },
		}
		local lines, close_keys = help.build(picker, {
			word = "cheese",
			method = "means_like",
			client = {
				key = "datamuse",
				available_methods = { means_like = "Means Like" },
				method_descriptions = { means_like = "words with a similar meaning" },
			},
			rank_jump = { enabled = true },
			capabilities = { parts_of_speech = true, rank_jump = true },
			target = { kind = "word" },
			mappings = {
				i = {
					["<F2>"] = actions.wrd_help,
					["<C-y>"] = actions.wrd_copy,
				},
				n = { ["g?"] = actions.wrd_help },
			},
		})

		assert.is_true(contains(lines, "Query: cheese"))
		assert.is_true(contains(lines, "Part-of-speech filter: Nouns"))
		assert.is_true(contains(lines, "i:<F2>"))
		assert.is_true(contains(lines, "n:g?"))
		assert.is_true(contains(lines, "replace the original word"))
		assert.are.same({ "i:<F2>", "n:g?" }, close_keys)
	end)

	it("does not advertise disabled rank navigation", function()
		local lines = help.build(nil, { rank_jump = { enabled = false } })

		assert.is_false(contains(lines, "build an original-rank jump"))
	end)

	it("does not advertise part-of-speech controls for clients without that metadata", function()
		local lines = help.build({}, {
			capabilities = { rank_jump = true, parts_of_speech = false },
			mappings = { i = { ["<C-j>"] = actions.wrd_cycle_part_of_speech } },
		})

		assert.is_false(contains(lines, "cycle part-of-speech filter"))
		assert.is_true(contains(lines, "build an original-rank jump"))
	end)

	it("describes method selection without advertising word-picker actions", function()
		local lines = help.build(nil, {
			_wrd_picker_kind = "methods",
			word = "cheese",
			client = { key = "custom" },
			mappings = { i = { ["<F1>"] = actions.wrd_help } },
		})

		assert.is_true(contains(lines, "fuzzy-filter available methods"))
		assert.is_true(contains(lines, "rerun the current query with this method"))
		assert.is_false(contains(lines, "replace the original"))
		assert.is_false(contains(lines, "build an original-rank jump"))
	end)

	it("describes configured cell navigation for the grid prototype", function()
		local lines = help.build({ _wrd = { grid = {} } }, {
			picker = { grid = { mappings = { left = "H", right = "L" } } },
		})

		assert.is_true(contains(lines, "Grid navigation"))
		assert.is_true(contains(lines, "H"))
		assert.is_true(contains(lines, "L"))
	end)
end)
