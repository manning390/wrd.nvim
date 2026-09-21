local wrd_actions = require("wrd.actions")
local refinement = require("wrd.refinement")

local M = {}

local documented_actions = {
	{ handler = wrd_actions.wrd_copy, description = "copy highlighted word without editing" },
	{ handler = wrd_actions.wrd_follow, description = "follow highlighted word with current method" },
	{ handler = wrd_actions.wrd_methods, description = "change method for the original query word" },
	{ handler = wrd_actions.wrd_change_word, description = "change the search word and rerun" },
	{
		handler = wrd_actions.wrd_cycle_part_of_speech,
		description = "cycle part-of-speech filter",
		capability = "refinement",
	},
	{ handler = wrd_actions.wrd_filter_all, description = "show all parts of speech", capability = "refinement" },
	{ handler = wrd_actions.wrd_filter_nouns, description = "show nouns", capability = "refinement" },
	{ handler = wrd_actions.wrd_filter_adjectives, description = "show adjectives", capability = "refinement" },
	{ handler = wrd_actions.wrd_filter_verbs, description = "show verbs", capability = "refinement" },
	{ handler = wrd_actions.wrd_filter_adverbs, description = "show adverbs", capability = "refinement" },
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
	local client = opts.client or {}
	local client_name = client.name or client.key or opts.client_key or "custom"
	local method_label = (client.available_methods or {})[opts.method] or opts.method or "unknown"
	local method_description = (client.method_descriptions or {})[opts.method]
	local filter = "All"
	local capabilities = {
		refinement = picker and picker._wrd_refinement ~= nil,
		rank_jump = opts._wrd_normalized and (opts.rank_jump or {}).enabled ~= false,
	}
	if capabilities.refinement then
		filter = refinement.label(picker._wrd_refinement.current()) or picker._wrd_refinement.current()
	end

	local lines = {
		"Wrd capabilities",
		"",
		string.format("Query: %s", opts.word or ""),
		string.format("Client: %s", client_name),
		string.format("Method: %s", method_label),
	}
	if capabilities.refinement then
		table.insert(lines, string.format("Part-of-speech filter: %s", filter))
	end
	if method_description then
		table.insert(lines, string.format("Meaning: %s", method_description))
	end

	vim.list_extend(lines, {
		"",
		"Search and navigate",
		"  text               fuzzy-filter eligible words",
		"  Backspace          delete fuzzy-search text",
		"  <C-n>/<C-p>, ↑/↓   move through results",
	})
	if capabilities.rank_jump then
		vim.list_extend(lines, {
			"  0-9                build an original-rank jump",
			"  Enter              resolve a pending rank immediately",
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
