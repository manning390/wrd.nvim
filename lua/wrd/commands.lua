return {
  setup = function()
    vim.api.nvim_create_user_command("Wrd", function(opts)
      local q, m = vim.fn.trim(opts.args), vim.g.telescope_wrd_config.default_method
      require("wrd").run({ word = (q ~= "" and q or "") })
    end, { nargs = "?" })
  end,
}
