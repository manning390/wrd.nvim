local M = {}

local function load_client(client_key)
	local ok, client = pcall(require, "wrd.clients." .. client_key)
	if not ok then
		error(string.format("Wrd Error: Client '%s' is not available", client_key))
	end

	return client
end

function M.attach_client(opts, config)
	opts = opts or {}
	config = config or {}

	if opts.client then
		return opts
	end

	if config.client then
		opts.client = config.client
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

function M.fetch(word, method, client)
	if not method or not word or word == "" then
		return nil
	end

	if not client or type(client.available_methods) ~= "table" or not client.available_methods[method] then
		local client_key = client and client.key or "unknown"
		error(string.format("Wrd Error: Method '%s' is not available on Client '%s'.", method, client_key))
	end

	if type(client[method]) ~= "function" then
		error(string.format("Wrd Error: Client '%s' does not implement method '%s'.", client.key or "unknown", method))
	end

	return client[method](word)
end

return M
