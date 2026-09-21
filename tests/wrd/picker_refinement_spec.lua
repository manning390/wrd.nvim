local saved_modules = {}
local module_names = {
	"telescope.actions.state",
	"telescope.finders",
	"wrd.picker_refinement",
}

describe("Telescope part-of-speech refinement", function()
	local picker
	local refresh_finder
	local refresh_opts
	local title
	local picker_refinement

	before_each(function()
		for _, name in ipairs(module_names) do
			saved_modules[name] = package.loaded[name]
		end

		picker = {
			layout = {
				results = {
					border = {
						change_title = function(_, value)
							title = value
						end,
					},
				},
			},
			refresh = function(_, finder, opts)
				refresh_finder = finder
				refresh_opts = opts
			end,
		}
		package.loaded["telescope.actions.state"] = {
			get_current_picker = function()
				return picker
			end,
		}
		package.loaded["telescope.finders"] = {
			new_table = function(opts)
				return opts
			end,
		}
		package.loaded["wrd.picker_refinement"] = nil
		picker_refinement = require("wrd.picker_refinement")
	end)

	after_each(function()
		for _, name in ipairs(module_names) do
			package.loaded[name] = saved_modules[name]
		end
	end)

	it("refreshes eligible entries without resetting the fuzzy prompt", function()
		local entries = {
			{ rank = 1, parts_of_speech = { "noun" } },
			{ rank = 2, parts_of_speech = { "verb" } },
			{ rank = 3, parts_of_speech = { "noun", "verb" } },
		}
		local entry_maker = function(entry)
			return entry
		end
		local state = picker_refinement.attach(42, entries, entry_maker)

		assert.are.equal("Words · All (3/3)", title)
		assert.is_true(state.refresh("noun"))
		assert.are.same({ entries[1], entries[3] }, refresh_finder.results)
		assert.are.equal(entry_maker, refresh_finder.entry_maker)
		assert.is_false(refresh_opts.reset_prompt)
		assert.are.equal("Words · Nouns (2/3)", title)
		assert.are.equal(title, picker.results_title)
	end)
end)
