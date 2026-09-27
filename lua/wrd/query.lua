local client_contract = require("wrd.client")

local M = {}

local function failure_message(message)
	message = tostring(message)
	local wrd_message = message:match("Wrd Error: (.*)")
	return "Wrd: " .. (wrd_message or message)
end

local function load_client(client_key)
	local ok, client = pcall(require, "wrd.clients." .. client_key)
	if not ok then
		error(string.format("Wrd Error: Client '%s' is not available", client_key))
	end

	return client_contract.validate(client)
end

function M.attach_client(opts, config)
	opts = opts or {}
	config = config or {}

	if opts.client then
		client_contract.validate(opts.client)
		opts.client_key = opts.client_key or opts.client.key
		return opts
	end

	if config.client then
		opts.client = client_contract.validate(config.client)
		opts.client_key = opts.client_key or config.client_key or config.client.key
		return opts
	end

	opts.client_key = opts.client_key or config.client_key
	if not opts.client_key or opts.client_key == "" then
		error("Wrd Error: A client or client_key is required")
	end

	opts.client = load_client(opts.client_key)
	return opts
end

local function validate_method(method, client)
	if not client or type(client.available_methods) ~= "table" or not client.available_methods[method] then
		local client_key = client and client.key or "unknown"
		error(string.format("Wrd Error: Method '%s' is not available on Client '%s'.", method, client_key))
	end

	if type(client[method]) ~= "function" then
		error(string.format("Wrd Error: Client '%s' does not implement method '%s'.", client.key or "unknown", method))
	end
end

function M.fetch(word, method, client)
	if not method or not word or word == "" then
		return nil
	end
	validate_method(method, client)

	local ok, response = pcall(client[method], word)
	if not ok then
		error(string.format("Wrd Error: Client '%s' method '%s' failed: %s", client.key or "unknown", method, response))
	end

	return response
end

function M.normalize(client, response)
	return client_contract.normalize(client, response)
end

function M.execute(word, method, client)
	if not method or not word or word == "" then
		return { status = "cancelled" }
	end
	validate_method(method, client)

	local ok, response = pcall(client[method], word)
	if not ok then
		return {
			status = "failed",
			message = string.format(
				"Wrd: Client '%s' method '%s' failed: %s",
				client.key or "unknown",
				method,
				response
			),
		}
	end

	local normalized, results, capabilities, issues = pcall(M.normalize, client, response)
	if not normalized then
		return { status = "failed", message = failure_message(results) }
	end
	if vim.tbl_isempty(results) then
		return {
			status = #issues > 0 and "unusable" or "empty",
			issues = issues,
		}
	end

	return {
		status = "ok",
		results = results,
		capabilities = capabilities,
		issues = issues,
	}
end

return M
