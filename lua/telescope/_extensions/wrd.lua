local ok, telescope = pcall(require, "telescope")

if not ok then
	error("Wrd Error: This plugin requires nvim-telescope/telescope.nvim")
end

local wrd = require("wrd")

return telescope.register_extension({
	setup = wrd.setup,
	exports = {
		run = wrd.run,
		methods = wrd.run_methods,
	},
})
