local ok, telescope = pcall(require, "telescope")

if not ok then
	error("Wrd Error: This plugin requires nvim-telescope/telescope.nvim")
end

local pickers = require("wrd.pickers")
local config = require("wrd.config")
local query = require("wrd.query")
local selection = require("wrd.selection")

local wrd = {}

function wrd.setup(opts)
	local current = config.setup(opts)

	if current.commands then
		require("wrd.commands").setup()
	end
end

-- opts {
--    word: string,
--    method: string
--    client_key: string
--    client: Client
--    mappings: { mode = { [key] = action } }
--    rank_jump: { enabled: boolean, delay_ms: number }
--    prompt: string
-- }
function wrd.run(opts)
	opts = opts or {}
	if opts.target == nil then
		opts.target = selection.capture()
	end

	if not config.is_setup() then
		wrd.setup()
	end
	local current = config.get()

	if not opts.client then
		opts = wrd._make_client(opts)
	end

	if not opts.method or opts.method == "" then
		local default_method = current.default_method
		if opts.method == "" or not default_method or default_method == "" then
			return wrd.run_methods(opts)
		else
			opts.method = default_method
		end
	end

	if not opts.word or opts.word == "" then
		opts.word = wrd._capture_hover(selection.text(opts.target))
	end

	if not opts.mappings then
		opts.mappings = current.mappings
	end
	if opts.rank_jump == nil then
		opts.rank_jump = current.rank_jump
	end

	-- Set our prompt
	local prompt = opts.prompt or opts.word
	if not opts.prompt then
		local query_title = opts.client.available_methods[opts.method]
		if query_title ~= "" then
			prompt = query_title .. ": " .. opts.word
		end
	end

	local data = wrd._fetch(opts.word, opts.method, opts.client)
	if data == nil then
		return
	end
	if vim.tbl_isempty(data) then
		local method_label = opts.client.available_methods[opts.method] or opts.method
		vim.notify(string.format("Wrd: No %s results for '%s'", method_label, opts.word), vim.log.levels.INFO)
		return
	end
	if type(opts.client.normalize) == "function" then
		data = opts.client.normalize(data)
		opts._wrd_normalized = true
		if vim.tbl_isempty(data) then
			vim.notify(string.format("Wrd: No usable results for '%s'", opts.word), vim.log.levels.INFO)
			return
		end
	end

	return pickers.word_picker(data, prompt, opts)
end

function wrd._make_client(opts)
	return query.attach_client(opts, config.get())
end

function wrd._fetch(word, query_method, client)
	return query.fetch(word, query_method, client)
end

function wrd.run_methods(opts)
	opts = opts or {}

	if not opts.client then
		opts = wrd._make_client(opts)
	end

	local callback = function(selection)
		wrd.run(vim.tbl_extend("keep", { method = selection }, opts))
	end

	return pickers.method_picker(
		opts.client.available_methods,
		callback,
		vim.tbl_extend("force", opts, { prompt_title = "Client Methods" })
	)
end

function wrd._capture_hover(default)
	return vim.fn.input("Word: ", default or vim.fn.expand("<cword>"))
end

return wrd
