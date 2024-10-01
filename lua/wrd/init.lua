local commands = require("wrd.commands")
local pickers = require("wrd.pickers")

local M = {}

function M.setup(config)
	config = vim.tbl_extend("keep", config or {}, {
		client_key = "datamuse",
		default_method = "means_like",
		commands = true,
	})

	vim.g.telescope_wrd_config = config
	vim.g.telescope_wrd_setup = true

	if config.commands then
		commands.setup()
	end
end

-- opts {
--    word: string,
--    method: string
--    client_key: string
--    client: Client
--    callbacks: {select: fn(selection), method: fn(selection), follow: fn(selection)}
--
--    Telescope opts
--    prompt_title: string
-- }
function M.run(opts)
	opts = opts or {}

	if not vim.g.telescope_wrd_setup then
		M.setup()
	end

	if not opts.client then
		opts = M.make_client(opts)
	end

	if not opts.method or opts.method == "" then
		local default_method = vim.g.telescope_wrd_config.default_method
		if opts.method == "" or not default_method or not default_method == "" then
			return M.run_methods(opts)
		else
			opts.method = default_method
		end
	end

	if not opts.word or opts.word == "" then
		opts.word = M._capture_hover()
	end

	-- Set our prompt
	local prompt = opts.word
	if not opts.prompt then
		local query_title = opts.client.available_methods[opts.method]
		if query_title ~= "" then
			prompt = query_title .. ": " .. opts.word
		end
	end

	local data = M.fetch(opts.word, opts.method, opts.client)
	local callbacks = opts.callbacks or M.default_callbacks(opts)

	return pickers.word_picker(data, prompt, callbacks, opts)
end

function M.make_client(opts)
	local client_key = opts.client_key or vim.g.telescope_wrd_config.client_key
	local ok, client = pcall(require, "wrd.clients." .. client_key)
	if not ok then
		error(string.format("Wrd Error: Client '%s' is not available", client_key))
	end
	opts.client = client
	return opts
end

function M.fetch(word, query_method, client)
	if not query_method or word == "" then
		return -- Early Escape for cancels
	end

	if not vim.tbl_contains(vim.tbl_keys(client.available_methods), query_method) then
		error(string.format("Wrd Error: Method '%s' is not available on Client '%s'.", query_method, client.key))
	end

	-- Run our query
	return client[query_method](word)
end

function M.default_callbacks(opts)
	return {
		select = function(selected_entry_value)
			local selected_word = opts.client.entry_selected(selected_entry_value)

			vim.fn.setreg("*", selected_word)
			vim.fn.setreg("@", selected_word)
			if vim.fn.expand("<cword>") ~= "" then
				vim.cmd("norm diw")
				vim.api.nvim_put({ selected_word }, "", false, true)
			end
		end,
		follow = function(selected_entry_value)
			local selected_word = opts.client.entry_selected(selected_entry_value)

			M.run(vim.tbl_extend("keep", { word = selected_word }, opts))
		end,
		methods = function(_)
			M.run_methods(vim.tbl_extend("keep", { method = "" }, opts))
		end,
	}
end

function M.run_methods(opts)
	opts = opts or {}

	if not opts.client then
		opts = M.make_client(opts)
	end

	local callback = function(selection)
		M.run(vim.tbl_extend("keep", { method = selection }, opts))
	end

	return pickers.method_picker(
		opts.client.available_methods,
		callback,
		vim.tbl_extend("force", opts, { prompt_title = "Client Methods" })
	)
end

function M._capture_hover()
	local cword = vim.fn.expand("<cword>")
	return vim.fn.input("Word: ", cword)
end

return M
