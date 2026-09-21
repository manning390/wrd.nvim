local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local data = vim.fn.stdpath("data")

local dependencies = {
	vim.env.PLENARY_PATH or (data .. "/lazy/plenary.nvim"),
	vim.env.TELESCOPE_PATH or (data .. "/lazy/telescope.nvim"),
}

vim.opt.shadafile = "NONE"
vim.o.loadplugins = false
vim.opt.runtimepath:prepend(root)

for _, path in ipairs(dependencies) do
	if vim.fn.isdirectory(path) == 0 then
		error("Missing test dependency: " .. path)
	end
	vim.opt.runtimepath:append(path)
end

vim.cmd.runtime("plugin/plenary.vim")
