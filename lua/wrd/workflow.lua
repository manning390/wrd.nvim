local config = require("wrd.config")
local descriptions = require("wrd.descriptions")
local pickers = require("wrd.pickers")
local query = require("wrd.query")
local selection = require("wrd.selection")
local session = require("wrd.session")

local M = {}

function M.new(dependencies)
	dependencies = dependencies or {}
	local workflow = {}

	local function prepare(opts)
		if not config.is_setup() then
			(dependencies.setup or config.setup)()
		end

		local current = config.get()
		local prepared = vim.tbl_extend("force", {}, opts or {})
		if prepared.target == nil then
			prepared.target = selection.capture()
		end
		query.attach_client(prepared, current)
		prepared.mappings = prepared.mappings or current.mappings
		if prepared.rank_jump == nil then
			prepared.rank_jump = current.rank_jump
		end
		prepared.picker = prepared.picker or current.picker
		return prepared, current
	end

	local function restore(lifecycle)
		if lifecycle and lifecycle.restore then
			lifecycle.restore()
		end
	end

	local function replace(lifecycle)
		if lifecycle and lifecycle.before_open then
			lifecycle.before_open()
		end
	end

	local function open_methods(opts, lifecycle)
		local callback = function(method)
			workflow.run(vim.tbl_extend("force", {}, opts, { method = method }), lifecycle)
		end

		return pickers.method_picker(
			opts.client.available_methods,
			callback,
			vim.tbl_extend("force", {}, opts, { prompt_title = "Client Methods", _wrd_picker_kind = "methods" }),
			lifecycle and lifecycle.restore
		)
	end

	function workflow.run(opts, lifecycle)
		local prepared, current = prepare(opts)
		if not prepared.method or prepared.method == "" then
			local default_method = current.default_method
			if prepared.method == "" or not default_method or default_method == "" then
				return open_methods(prepared, lifecycle)
			end
			prepared.method = default_method
		end

		if not prepared.word or prepared.word == "" then
			prepared.word = vim.fn.input("Word: ", selection.text(prepared.target) or vim.fn.expand("<cword>"))
		end

		local prompt = prepared.prompt or prepared.word
		if not prepared.prompt then
			local method_label = prepared.client.available_methods[prepared.method]
			if method_label ~= "" then
				prompt = method_label .. ": " .. prepared.word
			end
		end

		local outcome = query.execute(prepared.word, prepared.method, prepared.client)
		if outcome.status == "cancelled" then
			restore(lifecycle)
			return
		end
		if outcome.status == "failed" then
			vim.notify(outcome.message, vim.log.levels.ERROR)
			restore(lifecycle)
			return
		end
		if outcome.status == "empty" or outcome.status == "unusable" then
			local method_label = prepared.client.available_methods[prepared.method] or prepared.method
			local message = outcome.status == "unusable"
					and string.format("Wrd: No usable results for '%s'", prepared.word)
				or string.format("Wrd: No %s results for '%s'", method_label, prepared.word)
			vim.notify(message, vim.log.levels.INFO)
			restore(lifecycle)
			return
		end
		prepared.capabilities = outcome.capabilities

		local picker_session
		local function open_word(restore_state)
			return pickers.word_picker(outcome.results, prompt, prepared, picker_session, restore_state)
		end
		picker_session = session.new(prepared, {
			run = workflow.run,
			run_methods = workflow.methods,
			reopen = open_word,
		})
		replace(lifecycle)
		local opened = open_word()
		local definition_config = (prepared.picker or {}).query_definition or {}
		if definition_config.enabled ~= false and outcome.capabilities.describe then
			picker_session.set_query_definition({ status = "loading", word = prepared.word })
			descriptions.request(prepared.client, prepared.word, function(description)
				picker_session.set_query_definition(description)
			end)
		end
		return opened
	end

	function workflow.methods(opts, lifecycle)
		local prepared = prepare(opts)
		return open_methods(prepared, lifecycle)
	end

	return workflow
end

return M
