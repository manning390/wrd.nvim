local telescope = require("wrd.telescope")
local commands = require("wrd.commands")

local M = {}

function M.setup(config)
  config = vim.tbl_extend('force', {
    client = 'deatamuse',
    -- default_query = 'means_like',
    commands = true,
  }, config)

  vim.g.telescope_wrd_config = config
  vim.g.telescope_wrd_setup = true

  if config.commands then
    commands.setup()
  end
end

function M.run(method, opts)
  opts = opts or {}

  if not vim.g.telescope_wrd_setup then
    M.setup()
  end

  local client = M.makeClient(opts)

  if not method or method == '' then
    return M.methods(opts)
  end

  local word = M.captureHover()
  local data, prompt = M.fetch(word, method, client)

  local callback = opts.callback or M.defaultCallback(client)

  telescope.word_picker(data, prompt, callback, opts)
end

function M.makeClient(opts)
  local client_key = opts.client or vim.g.telescope_wrd_config.client
  local ok, client = pcall(require, 'wrd.clients.' .. client_key)
  if not ok then
    error(string.format("Wrd Error: Client '%s' is not available", client_key))
  end
  return client
end

function M.fetch(word, query_method, client)
  if not query_method or word == "" then
    return -- Early Escape for cancels
  end

  if not vim.tbl_contains(client.available_methods, query_method) then
    error(string.format("Wrd Error: Method '%s' is not available on Client '%s'.", query_method, client.key))
  end

  -- Run our query
  local data, query_title = client[query_method](word)

  -- Set our prompt
  local prompt = word
  if query_title ~= "" then
    prompt = query_title .. ": " .. word
  end

  return data, prompt
end

function M.defaultCallback(client)
  return function(selected_entry_value)
    local selected_word = client.entry_selected(selected_entry_value)
    vim.fn.setreg("@", selected_word)
    if vim.fn.expand("<cword>") ~= "" then
      vim.cmd('norm diw')
      vim.api.nvim_put({ selected_word }, "", false, true)
    end
  end
end

function M.methods(opts)
  opts = opts or {}

  local client = M.makeClient(opts)
  local callback = function(selection)
    M.run(selection, opts)
  end
  telescope.simple_picker(client.available_methods, callback, opts)
end


function M._captureHover()
  local cword = vim.fn.expand('<cword>')
  return vim.fn.input("Word: ", cword)
end

return M
