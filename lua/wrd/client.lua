local result = require("wrd.result")

local M = {}

local function client_name(client)
	return type(client) == "table" and client.key or "unknown"
end

---@class WrdClient
---@field key string Stable identifier used in messages and configuration.
---@field name? string Human-readable display name.
---@field available_methods table<string, string> Method keys and display labels.
---@field method_descriptions? table<string, string> Optional help text for methods.
---@field normalize fun(response: any): WrdResult[] Convert a provider response to Wrd results.
---@field capabilities? { parts_of_speech?: boolean } Optional capabilities not safely inferred from results.

---@class WrdDefinition
---@field text string
---@field part_of_speech? "noun"|"verb"|"adjective"|"adverb"
---@field source? string|table

---@class WrdResult
---@field word string
---@field rank? integer
---@field score? number
---@field parts_of_speech? string[]
---@field definitions? WrdDefinition[]
---@field provenance? string|table
---@field origin? string|table
---@field concept? string|table
---@field raw? any Provider-specific data retained for integrations.

function M.validate(client)
	if type(client) ~= "table" then
		error("Wrd Error: Client must be a table")
	end
	if type(client.key) ~= "string" or client.key == "" then
		error("Wrd Error: Client key must be a non-empty string")
	end
	if type(client.available_methods) ~= "table" then
		error(string.format("Wrd Error: Client '%s' must define available_methods", client.key))
	end
	if next(client.available_methods) == nil then
		error(string.format("Wrd Error: Client '%s' must advertise at least one method", client.key))
	end
	if type(client.normalize) ~= "function" then
		error(string.format("Wrd Error: Client '%s' must implement normalize(response)", client.key))
	end
	if client.method_descriptions ~= nil and type(client.method_descriptions) ~= "table" then
		error(string.format("Wrd Error: Client '%s' method_descriptions must be a table", client.key))
	end
	if client.capabilities ~= nil then
		if type(client.capabilities) ~= "table" then
			error(string.format("Wrd Error: Client '%s' capabilities must be a table", client.key))
		end
		for capability, enabled in pairs(client.capabilities) do
			if capability ~= "parts_of_speech" then
				error(string.format("Wrd Error: Client '%s' advertises unsupported capability '%s'", client.key, capability))
			end
			if type(enabled) ~= "boolean" then
				error(string.format("Wrd Error: Client '%s' capability '%s' must be boolean", client.key, capability))
			end
		end
	end

	for method, label in pairs(client.available_methods) do
		if type(method) ~= "string" or method == "" or type(label) ~= "string" then
			error(string.format("Wrd Error: Client '%s' has an invalid method declaration", client.key))
		end
		if type(client[method]) ~= "function" then
			error(string.format("Wrd Error: Client '%s' does not implement method '%s'.", client.key, method))
		end
	end

	return client
end

function M.normalize(client, response)
	M.validate(client)
	local ok, values = pcall(client.normalize, response)
	if not ok then
		error(string.format("Wrd Error: Client '%s' failed to normalize results: %s", client_name(client), values))
	end
	if type(values) ~= "table" then
		error(string.format("Wrd Error: Client '%s' normalize(response) must return a list", client.key))
	end
	if #values == 0 and next(values) ~= nil then
		error(string.format("Wrd Error: Client '%s' normalize(response) must return a list", client.key))
	end

	local normalized, issues, inferred = result.prepare(values)
	for _, issue in ipairs(issues) do
		vim.notify(string.format("Wrd: Client '%s' skipped result #%d: %s", client.key, issue.index, issue.reason), vim.log.levels.WARN)
	end

	local declared = client.capabilities or {}
	return normalized, {
		parts_of_speech = declared.parts_of_speech == true or inferred.parts_of_speech,
		rank_jump = true,
	}, issues
end

return M
