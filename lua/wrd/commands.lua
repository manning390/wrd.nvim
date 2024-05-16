return {
  setup = function()
    vim.api.nvim_create_user_command('Wrd', function(opts)
      local q, d = vim.fn.trim(opts.args), vim.g.telescope_wrd_config.default_query
      require('wrd').run(q ~= '' and q or d or '')
    end, { nargs = '?' })
  end
}
