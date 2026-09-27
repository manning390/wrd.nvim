local config = require("wrd.config")
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

	local function open_methods(opts)
		local callback = function(method)
			workflow.run(vim.tbl_extend("force", {}, opts, { method = method }))
		end

		return pickers.method_picker(
			opts.client.available_methods,
			callback,
			vim.tbl_extend("force", {}, opts, { prompt_title = "Client Methods", _wrd_picker_kind = "methods" })
		)
	end

	function workflow.run(opts)
		local prepared, current = prepare(opts)
		if not prepared.method or prepared.method == "" then
			local default_method = current.default_method
			if prepared.method == "" or not default_method or default_method == "" then
				return open_methods(prepared)
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

		local response = query.fetch(prepared.word, prepared.method, prepared.client)
		if response == nil then
			return
		end
		local data, capabilities, issues = query.normalize(prepared.client, response)
		if vim.tbl_isempty(data) then
			local method_label = prepared.client.available_methods[prepared.method] or prepared.method
			local message = #issues > 0 and string.format("Wrd: No usable results for '%s'", prepared.word)
				or string.format("Wrd: No %s results for '%s'", method_label, prepared.word)
			vim.notify(message, vim.log.levels.INFO)
			return
		end
		prepared.capabilities = capabilities

		local picker_session = session.new(prepared, {
			run = workflow.run,
			run_methods = workflow.methods,
		})
		return pickers.word_picker(data, prompt, prepared, picker_session)
	end

	function workflow.methods(opts)
		local prepared = prepare(opts)
		return open_methods(prepared)
	end

	return workflow
end

return M
