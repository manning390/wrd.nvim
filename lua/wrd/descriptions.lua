local client_contract = require("wrd.client")

local M = {}
local cache = setmetatable({}, { __mode = "k" })
local pending = setmetatable({}, { __mode = "k" })

local function word_key(word)
	return vim.trim(word):lower()
end

local function client_values(store, client)
	store[client] = store[client] or {}
	return store[client]
end

local function deliver(callbacks, outcome)
	for _, callback in ipairs(callbacks) do
		callback(outcome)
	end
end

function M.request(client, word, callback)
	if type(client) ~= "table" or type(client.describe) ~= "function" then
		callback({ status = "unsupported" })
		return
	end
	if type(word) ~= "string" or vim.trim(word) == "" then
		callback({ status = "empty" })
		return
	end

	local key = word_key(word)
	local cached = client_values(cache, client)[key]
	if cached then
		callback(cached)
		return
	end

	local client_pending = client_values(pending, client)
	if client_pending[key] then
		table.insert(client_pending[key], callback)
		return
	end
	client_pending[key] = { callback }

	local settled = false
	local function complete(err, value)
		if settled then
			return
		end
		settled = true
		local callbacks = client_pending[key]
		client_pending[key] = nil

		if err then
			deliver(callbacks, { status = "failed", message = tostring(err) })
			return
		end

		local ok, normalized = pcall(client_contract.normalize_description, client, word, value)
		if not ok then
			deliver(callbacks, { status = "failed", message = tostring(normalized) })
			return
		end
		local outcome = normalized and #normalized.definitions > 0 and { status = "ok", result = normalized }
			or { status = "empty" }
		client_values(cache, client)[key] = outcome
		deliver(callbacks, outcome)
	end

	local ok, handle = pcall(client.describe, word, complete)
	if not ok then
		complete(handle)
		return
	end
	return handle
end

function M.clear()
	cache = setmetatable({}, { __mode = "k" })
	pending = setmetatable({}, { __mode = "k" })
end

return M
