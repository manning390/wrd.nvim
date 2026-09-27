local saved_modules = {}
local selection
local closed_prompt
local followed_word
local methods_requested
local changed_word
local current_picker
local copied_word
local applied_target
local restored_prompt
local transition_lifecycle
local reopened_state
local wrd_actions

local module_names = {
	"telescope.actions",
	"telescope.actions.state",
	"wrd.actions",
	"wrd.picker_controller",
	"wrd.selection",
}

describe("wrd picker actions", function()
	before_each(function()
		for _, name in ipairs(module_names) do
			saved_modules[name] = package.loaded[name]
		end

		selection = nil
		closed_prompt = nil
		followed_word = nil
		methods_requested = false
		changed_word = nil
		current_picker = nil
		copied_word = nil
		applied_target = nil
		restored_prompt = nil
		transition_lifecycle = nil
		reopened_state = nil

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

	local function attach_session(query_word, target)
		current_picker = {
			_wrd = {
				restore_prompt = function(insert_mode) restored_prompt = insert_mode end,
				snapshot = function(insert_mode)
					return { prompt = "fuzzy", rank = 3, filter = "noun", insert_mode = insert_mode }
				end,
				session = {
					query_word = query_word,
					target = target,
					follow = function(word, lifecycle)
						followed_word = word
						transition_lifecycle = lifecycle
					end,
					choose_method = function(lifecycle)
						methods_requested = true
						transition_lifecycle = lifecycle
					end,
					change_word = function(word, lifecycle)
						changed_word = word
						transition_lifecycle = lifecycle
					end,
					reopen = function(state) reopened_state = state end,
				},
			},
		}
	end

	after_each(function()
		for _, name in ipairs(module_names) do
			package.loaded[name] = saved_modules[name]
		end
	end)

	it("keeps the current picker until a followed query is ready", function()
		attach_session("cheese")
		selection = {
			wrd = {
				word = "parmesan",
			},
		}

		wrd_actions.wrd_follow(0)

		assert.is_nil(closed_prompt)
		assert.are.equal("parmesan", followed_word)
		transition_lifecycle.before_open()
		assert.are.equal(0, closed_prompt)
	end)

	it("snapshots and closes the current picker before method selection", function()
		attach_session("cheese")

		wrd_actions.wrd_methods(0)

		assert.are.equal(0, closed_prompt)
		assert.is_true(methods_requested)
		transition_lifecycle.restore()
		assert.are.equal("fuzzy", reopened_state.prompt)
		assert.are.equal(3, reopened_state.rank)
		assert.are.equal("noun", reopened_state.filter)
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
		attach_session("cheese", target)

		wrd_actions.wrd_change_word(0)
		assert.are.equal("cheese", input_opts.default)
		assert.is_nil(closed_prompt)
		input_callback(" bread ")
		vim.ui.input = original_input

		assert.are.equal("bread", changed_word)
		assert.is_nil(restored_prompt)
		assert.is_nil(closed_prompt)
		assert.is_not_nil(transition_lifecycle)
	end)

	it("restores picker focus after cancelling a query-word change", function()
		local input_callback
		local original_input = vim.ui.input
		vim.ui.input = function(_, callback) input_callback = callback end
		attach_session("cheese")

		wrd_actions.wrd_change_word(42)
		input_callback(nil)
		vim.ui.input = original_input

		assert.is_not_nil(restored_prompt)
		assert.is_nil(closed_prompt)
		assert.is_nil(changed_word)
	end)

	it("does nothing when no result is selected", function()
		wrd_actions.wrd_select(21)
		wrd_actions.wrd_follow(42)
		wrd_actions.wrd_methods(84)

		assert.is_nil(closed_prompt)
		assert.is_nil(followed_word)
		assert.is_false(methods_requested)
	end)

	it("copies and applies the selected word to its captured origin target", function()
		local target = { kind = "word", bufnr = 1 }
		attach_session("cheese", target)
		selection = {
			wrd = {
				word = "parmesan",
			},
		}

		wrd_actions.wrd_select(21)

		assert.are.equal("parmesan", copied_word)
		assert.are.equal(target, applied_target)
		assert.are.equal(21, closed_prompt)
	end)

	it("supports copying without applying an origin target", function()
		selection = { wrd = { word = "parmesan" } }

		wrd_actions.wrd_copy(21)

		assert.are.equal("parmesan", copied_word)
		assert.is_nil(applied_target)
		assert.are.equal(21, closed_prompt)
	end)

	it("cycles the active picker part-of-speech filter", function()
		local cycled = false
		current_picker = {
			_wrd = { filters = {
				refresh_next = function()
					cycled = true
				end,
			} },
		}

		wrd_actions.wrd_cycle_part_of_speech(42)

		assert.is_true(cycled)
	end)

	it("exposes direct part-of-speech actions for custom mappings", function()
		local selected_filter
		current_picker = {
			_wrd = { filters = {
				refresh = function(part_of_speech)
					selected_filter = part_of_speech
				end,
			} },
		}

		wrd_actions.wrd_filter_adjectives(42)

		assert.are.equal("adjective", selected_filter)
	end)

	it("ignores filter actions for pickers without filter state", function()
		current_picker = {}

		assert.has_no.errors(function()
			wrd_actions.wrd_filter_nouns(42)
		end)
	end)

	it("toggles picker-local help state", function()
		local toggled = false
		current_picker = {
			_wrd = { help = {
				toggle = function()
					toggled = true
				end,
			} },
		}

		wrd_actions.wrd_help(42)

		assert.is_true(toggled)
	end)
end)
