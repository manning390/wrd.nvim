local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewer = require "telescope.previewers"
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

function M.word_picker(data, prompt, callback, opts)
  pickers.new(opts, {
    prompt_title = prompt,
    finder = finders.new_table {
      results = data,
      entry_maker = function(entry) return entry end,
      static = true
    },
    sorter = conf.generic_sorter(opts),
    previewer = previewer.new_buffer_previewer {
      define_preview = function(self, entry, status)
        vim.wo[self.state.winid].wrap = true
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false,
          entry.value.defs or {})
      end,
      title = 'Definition',
    },
    attach_mappings = function(bufnr, map)
      actions.select_default:replace(function()
        actions.close(bufnr)
        local selection = action_state.get_selected_entry().value
        callback(selection)
      end)
      return true
    end,
  }):find()
end

function M.simple_picker(data, callback, opts)
  pickers.new(opts, {
    prompt_title = 'Client Methods',
    finder = finders.new_table {
      results = data
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(bufnr, map)
      actions.select_default:replace(function()
        actions.close(bufnr)
        local selection = action_state.get_selected_entry().value
        callback(selection)
      end)
      return true
    end
  }):find()
end

return M
