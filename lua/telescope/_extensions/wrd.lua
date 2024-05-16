local ok, telescope = pcall(require, "telescope")

if not ok then
    error "Wrd Error: This plugin requires nvim-telescope/telescope.nvim"
end

return telescope.register_extension {
    setup = require("wrd").setup,
    exports = {
        wrd = require("wrd").wrd
    },
}
