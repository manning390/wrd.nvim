local M = {}

local default_config = {
	client_key = "datamuse",
	default_method = "means_like",
	commands = true,
	-- Defined / consumed in lua/telescope/_extensions/wrd.lua
	-- telescope = {
	-- 	mappings = {
	-- 		i = {
	-- 			["<tab>"] = require("telescope._extensions.wrd.actions").follow,
	-- 			["/"] = require("telescope._extensions.wrd.actions").methods,
	-- 		},
	-- 		n = {
	-- 			["<tab>"] = require("telescope._extensions.wrd.actions").follow,
	-- 			["/"] = require("telescope._extensions.wrd.actions").methods,
	-- 		},
	-- 	},
	-- },
}

function M.setup(config)
	config = vim.tbl_extend("keep", config or {}, default_config)

	vim.g.telescope_wrd_config = config
	vim.g.telescope_wrd_setup = true

	if config.commands then
		require("wrd.commands").setup()
	end

	require("telescope").load_extension("wrd")
	require("telescope").extensions.wrd.setup(config.telescope or {})
end

return M
