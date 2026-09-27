local M = {}

local values

local function invalid(path, expectation, value)
	error(string.format("Wrd Error: config.%s must be %s (got %s)", path, expectation, type(value)), 0)
end

local function expect_type(config, key, expected, path)
	if type(config[key]) ~= expected then
		invalid(path or key, expected, config[key])
	end
end

local function expect_positive_number(config, key, path)
	if type(config[key]) ~= "number" or config[key] <= 0 then
		invalid(path or key, "a positive number", config[key])
	end
end

local function expect_positive_integer(config, key, path)
	if type(config[key]) ~= "number" or config[key] <= 0 or config[key] % 1 ~= 0 then
		invalid(path or key, "a positive integer", config[key])
	end
end

local function validate(config)
	expect_type(config, "client_key", "string")
	if config.client_key == "" then
		invalid("client_key", "a non-empty string", config.client_key)
	end
	expect_type(config, "default_method", "string")
	expect_type(config, "commands", "boolean")
	if config.client ~= nil and type(config.client) ~= "table" then
		invalid("client", "a client table", config.client)
	end

	expect_type(config, "rank_jump", "table")
	expect_type(config.rank_jump, "enabled", "boolean", "rank_jump.enabled")
	if type(config.rank_jump.delay_ms) ~= "number" or config.rank_jump.delay_ms < 0 then
		invalid("rank_jump.delay_ms", "a non-negative number", config.rank_jump.delay_ms)
	end

	expect_type(config, "picker", "table")
	if config.picker.presentation ~= "list" and config.picker.presentation ~= "grid" then
		error(
			string.format(
				"Wrd Error: config.picker.presentation must be 'list' or 'grid' (got %s)",
				vim.inspect(config.picker.presentation)
			),
			0
		)
	end
	expect_type(config.picker, "layout_strategy", "string", "picker.layout_strategy")
	if config.picker.layout_strategy == "" then
		invalid("picker.layout_strategy", "a non-empty string", config.picker.layout_strategy)
	end
	expect_type(config.picker, "layout_config", "table", "picker.layout_config")
	expect_type(config.picker, "show_part_of_speech", "boolean", "picker.show_part_of_speech")
	expect_type(config.picker, "query_definition", "table", "picker.query_definition")
	expect_type(config.picker.query_definition, "enabled", "boolean", "picker.query_definition.enabled")
	expect_positive_integer(
		config.picker.query_definition,
		"max_definitions",
		"picker.query_definition.max_definitions"
	)

	expect_type(config.picker, "grid", "table", "picker.grid")
	expect_positive_integer(config.picker.grid, "columns", "picker.grid.columns")
	expect_positive_integer(config.picker.grid, "cell_width", "picker.grid.cell_width")
	expect_type(config.picker.grid, "separator", "string", "picker.grid.separator")
	expect_positive_number(config.picker.grid, "preview_width", "picker.grid.preview_width")
	expect_type(config.picker.grid, "show_part_of_speech", "boolean", "picker.grid.show_part_of_speech")
	expect_type(config.picker.grid, "mappings", "table", "picker.grid.mappings")
	for _, direction in ipairs({ "left", "right" }) do
		local mapping = config.picker.grid.mappings[direction]
		if mapping ~= false and (type(mapping) ~= "string" or mapping == "") then
			invalid("picker.grid.mappings." .. direction, "a non-empty string or false", mapping)
		end
	end

	expect_type(config, "mappings", "table")
	for _, mode in ipairs({ "i", "n" }) do
		if config.mappings[mode] ~= nil and type(config.mappings[mode]) ~= "table" then
			invalid("mappings." .. mode, "a table", config.mappings[mode])
		end
	end

	return config
end

local function defaults()
	local actions = require("wrd.actions")

	return {
		client_key = "datamuse",
		default_method = "means_like",
		commands = true,
		rank_jump = {
			enabled = true,
			delay_ms = 600,
		},
		picker = {
			presentation = "list",
			layout_strategy = "horizontal",
			layout_config = {
				width = 0.95,
				height = 0.95,
				horizontal = {
					preview_width = 0.55,
					preview_cutoff = 100,
				},
			},
			show_part_of_speech = true,
			query_definition = {
				enabled = true,
				max_definitions = 2,
			},
			grid = {
				columns = 5,
				cell_width = 18,
				separator = " │ ",
				preview_width = 0.4,
				show_part_of_speech = false,
				mappings = {
					left = "<C-Left>",
					right = "<C-Right>",
				},
			},
		},
		mappings = {
			i = {
				["<C-e>"] = actions.wrd_change_word,
				["<C-j>"] = actions.wrd_cycle_part_of_speech,
				["<C-y>"] = actions.wrd_copy,
				["<F1>"] = actions.wrd_help,
				["<tab>"] = actions.wrd_methods,
				["/"] = actions.wrd_follow,
			},
			n = {
				["<C-e>"] = actions.wrd_change_word,
				["<C-j>"] = actions.wrd_cycle_part_of_speech,
				["<C-y>"] = actions.wrd_copy,
				["<F1>"] = actions.wrd_help,
				["<tab>"] = actions.wrd_methods,
				["/"] = actions.wrd_follow,
			},
		},
	}
end

function M.setup(opts)
	if opts ~= nil and type(opts) ~= "table" then
		invalid("setup", "a table", opts)
	end
	local merged = vim.tbl_deep_extend("force", defaults(), opts or {})
	values = validate(merged)
	return values
end

function M.get()
	if not values then
		return M.setup()
	end

	return values
end

function M.is_setup()
	return values ~= nil
end

function M.defaults()
	return defaults()
end

return M
