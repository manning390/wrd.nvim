local saved_modules = {}
local selection
local closed_prompt
local run_opts
local method_opts
local current_picker
local copied_word
local applied_target
local wrd_actions

local module_names = {
	"telescope.actions",
	"telescope.actions.state",
	"wrd",
	"wrd.actions",
	"wrd.selection",
}

describe("wrd picker actions", function()
	before_each(function()
		for _, name in ipairs(module_names) do
			saved_modules[name] = package.loaded[name]
		end

		selection = nil
		closed_prompt = nil
		run_opts = nil
		method_opts = nil
		current_picker = nil
		copied_word = nil
		applied_target = nil

		package.loaded["telescope.actions"] = {
			close = function(prompt_bufnr)
				closed_prompt = prompt_bufnr
			end,
		}
		package.loaded["telescope.actions.state"] = {
			get_selected_entry = function()
				return selection
			end,
			get_current_picker = function()
				return current_picker
			end,
		}
		package.loaded["wrd"] = {
			run = function(opts)
				run_opts = opts
			end,
			run_methods = function(opts)
				method_opts = opts
			end,
		}
		package.loaded["wrd.selection"] = {
			set_registers = function(word)
				copied_word = word
			end,
			apply = function(target)
				applied_target = target
				return true
			end,
		}
		package.loaded["wrd.actions"] = nil
		wrd_actions = require("wrd.actions")
	end)

	after_each(function()
		for _, name in ipairs(module_names) do
			package.loaded[name] = saved_modules[name]
		end
	end)

	it("closes the current picker and follows the highlighted word", function()
		local original_opts = { word = "cheese", method = "means_like" }
		selection = {
			wrd = {
				word = "parmesan",
				opts = original_opts,
			},
		}

		wrd_actions.wrd_follow(42)

		assert.are.equal(42, closed_prompt)
		assert.are.equal("parmesan", run_opts.word)
		assert.are.equal("means_like", run_opts.method)
		assert.are.equal("cheese", original_opts.word)
	end)

	it("changes method for the current query word after closing the picker", function()
		selection = {
			wrd = {
				word = "parmesan",
				opts = { word = "cheese", method = "means_like" },
			},
		}

		wrd_actions.wrd_methods(84)

		assert.are.equal(84, closed_prompt)
		assert.are.equal("cheese", method_opts.word)
		assert.are.equal("", method_opts.method)
	end)

	it("changes the current query word while preserving its insertion target", function()
		local input_opts
		local input_callback
		local original_input = vim.ui.input
		vim.ui.input = function(opts, callback)
			input_opts = opts
			input_callback = callback
		end
		local target = { kind = "word", bufnr = 7 }
		selection = {
			wrd = {
				word = "parmesan",
				opts = { word = "cheese", method = "means_like", target = target },
			},
		}

		wrd_actions.wrd_change_word(0)
		assert.are.equal("cheese", input_opts.default)
		assert.is_nil(closed_prompt)
		input_callback(" bread ")
		vim.ui.input = original_input

		assert.are.equal("bread", run_opts.word)
		assert.are.equal("means_like", run_opts.method)
		assert.are.equal(target, run_opts.target)
	end)

	it("does nothing when no result is selected", function()
		wrd_actions.wrd_select(21)
		wrd_actions.wrd_follow(42)
		wrd_actions.wrd_methods(84)

		assert.is_nil(closed_prompt)
		assert.is_nil(run_opts)
		assert.is_nil(method_opts)
	end)

	it("copies and applies the selected word to its captured origin target", function()
		local target = { kind = "word", bufnr = 1 }
		selection = {
			wrd = {
				word = "parmesan",
				opts = { target = target },
			},
		}

		wrd_actions.wrd_select(21)

		assert.are.equal("parmesan", copied_word)
		assert.are.equal(target, applied_target)
		assert.are.equal(21, closed_prompt)
	end)

	it("supports copying without applying an origin target", function()
		selection = { wrd = { word = "parmesan", opts = {} } }

		wrd_actions.wrd_copy(21)

		assert.are.equal("parmesan", copied_word)
		assert.is_nil(applied_target)
		assert.are.equal(21, closed_prompt)
	end)

	it("cycles the active picker part-of-speech refinement", function()
		local cycled = false
		current_picker = {
			_wrd_refinement = {
				refresh_next = function()
					cycled = true
				end,
			},
		}

		wrd_actions.wrd_cycle_part_of_speech(42)

		assert.is_true(cycled)
	end)

	it("exposes direct part-of-speech actions for custom mappings", function()
		local selected_filter
		current_picker = {
			_wrd_refinement = {
				refresh = function(part_of_speech)
					selected_filter = part_of_speech
				end,
			},
		}

		wrd_actions.wrd_filter_adjectives(42)

		assert.are.equal("adjective", selected_filter)
	end)

	it("ignores refinement actions for pickers without refinement state", function()
		current_picker = {}

		assert.has_no.errors(function()
			wrd_actions.wrd_filter_nouns(42)
		end)
	end)

	it("toggles picker-local help state", function()
		local toggled = false
		current_picker = {
			_wrd_help = {
				toggle = function()
					toggled = true
				end,
			},
		}

		wrd_actions.wrd_help(42)

		assert.is_true(toggled)
	end)
end)
