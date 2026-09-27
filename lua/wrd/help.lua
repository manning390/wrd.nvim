local wrd_actions = require("wrd.actions")
local filters = require("wrd.filters")

local M = {}

local documented_actions = {
	{ handler = wrd_actions.wrd_copy, description = "copy highlighted word without editing" },
	{ handler = wrd_actions.wrd_follow, description = "follow highlighted word with current method" },
	{ handler = wrd_actions.wrd_methods, description = "change method for the original query word" },
	{ handler = wrd_actions.wrd_change_word, description = "change the search word and rerun" },
	{
		handler = wrd_actions.wrd_cycle_part_of_speech,
		description = "cycle part-of-speech filter",
		capability = "filters",
	},
	{ handler = wrd_actions.wrd_filter_all, description = "show all parts of speech", capability = "filters" },
	{ handler = wrd_actions.wrd_filter_nouns, description = "show nouns", capability = "filters" },
	{ handler = wrd_actions.wrd_filter_adjectives, description = "show adjectives", capability = "filters" },
	{ handler = wrd_actions.wrd_filter_verbs, description = "show verbs", capability = "filters" },
	{ handler = wrd_actions.wrd_filter_adverbs, description = "show adverbs", capability = "filters" },
	{ handler = wrd_actions.wrd_help, description = "toggle this help" },
}

local function effective_keys(mappings, handler)
	local keys = {}
	for _, mode in ipairs({ "i", "n" }) do
		for key, action in pairs((mappings or {})[mode] or {}) do
			if action == handler then
				table.insert(keys, string.format("%s:%s", mode, key))
			end
		end
	end
	table.sort(keys)
	return keys
end

local function append_mapping(lines, mappings, item, capabilities)
	if item.capability and not capabilities[item.capability] then
		return
	end
	local keys = effective_keys(mappings, item.handler)
	if #keys > 0 then
		table.insert(lines, string.format("  %-18s %s", table.concat(keys, ", "), item.description))
	end
end

local function selection_description(target)
	if not target then
		return "copy highlighted word (no editable origin target)"
	elseif target.kind == "word" then
		return "replace the original word and copy it"
	elseif target.kind == "range" then
		return "replace the original visual selection and copy it"
	elseif target.kind == "line" then
		return "replace the selected original lines and copy it"
	elseif target.kind == "block" then
		return "copy highlighted word (block selections are not replaced)"
	end
	return "insert at the original cursor and copy it"
end

function M.build(picker, opts)
	opts = opts or {}
	local method_picker = opts._wrd_picker_kind == "methods"
	local client = opts.client or {}
	local client_name = client.name or client.key or opts.client_key or "custom"
	local method_label = (client.available_methods or {})[opts.method] or opts.method
	local method_description = (client.method_descriptions or {})[opts.method]
	local filter = "All"
	local capabilities = {
		filters = not method_picker and picker and picker._wrd and picker._wrd.filters ~= nil,
		grid = not method_picker and picker and picker._wrd and picker._wrd.grid ~= nil,
		rank_jump = not method_picker
			and (opts.capabilities or {}).rank_jump == true
			and (opts.rank_jump or {}).enabled ~= false,
	}
	if capabilities.filters then
		filter = filters.label(picker._wrd.filters.current()) or picker._wrd.filters.current()
	end

	local lines = {
		"Wrd capabilities",
		"",
		string.format("Query: %s", opts.word or ""),
		string.format("Client: %s", client_name),
	}
	if method_label and method_label ~= "" then
		table.insert(lines, string.format("Method: %s", method_label))
	end
	if capabilities.filters then
		table.insert(lines, string.format("Part-of-speech filter: %s", filter))
	end
	if method_description then
		table.insert(lines, string.format("Meaning: %s", method_description))
	end

	vim.list_extend(lines, {
		"",
		"Search and navigate",
		method_picker and "  text               fuzzy-filter available methods"
			or "  text               fuzzy-filter eligible words",
		"  Backspace          delete fuzzy-search text",
		"  <C-n>/<C-p>, ↑/↓   move through results",
	})
	if method_picker then
		vim.list_extend(lines, {
			"",
			"Choose a method",
			"  Enter              rerun the current query with this method",
		})
		for _, item in ipairs(documented_actions) do
			if item.handler == wrd_actions.wrd_help then
				append_mapping(lines, opts.mappings, item, capabilities)
			end
		end
		vim.list_extend(lines, {
			"",
			"Picker",
			"  <C-c>/Escape       close the method picker",
		})
		return lines, effective_keys(opts.mappings, wrd_actions.wrd_help)
	end
	if capabilities.rank_jump then
		vim.list_extend(lines, {
			"  0-9                build an original-rank jump",
			"  Enter              resolve a pending rank immediately",
		})
	end
	if capabilities.grid then
		local grid_mappings = (((opts.picker or {}).grid or {}).mappings or {})
		vim.list_extend(lines, {
			"",
			"Grid navigation",
			string.format("  %-18s move to the cell on the left", grid_mappings.left or "unmapped"),
			string.format("  %-18s move to the cell on the right", grid_mappings.right or "unmapped"),
			"  ↑/↓                move within the active grid column",
		})
	end

	vim.list_extend(lines, {
		"",
		"Use the highlighted word",
		string.format("  %-18s %s", "Enter", selection_description(opts.target)),
	})
	for _, item in ipairs(documented_actions) do
		append_mapping(lines, opts.mappings, item, capabilities)
	end

	vim.list_extend(lines, {
		"",
		"Preview and picker",
		"  <C-u>/<C-d>        scroll the definition preview",
		"  <C-/> or n:?       Telescope's generic mapping help",
		"  <C-c>/Escape       close the picker",
	})

	return lines, effective_keys(opts.mappings, wrd_actions.wrd_help)
end

return M
