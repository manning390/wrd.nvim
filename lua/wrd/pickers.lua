local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewer = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local M = {}

function M.word_picker(data, prompt, callbacks, opts)
  pickers
      .new(opts, {
        prompt_title = prompt,
        finder = finders.new_table({
          results = data,
          entry_maker = function(entry)
            return entry
          end,
          static = true,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewer.new_buffer_previewer({
          define_preview = function(self, entry, status)
            vim.wo[self.state.winid].wrap = true
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.defs or {})
          end,
          title = "Definition",
        }),
        attach_mappings = function(_, map)
          -- i,n <cr>
          actions.select_default:replace(function(prompt_bufnr)
            actions.close(prompt_bufnr)
            callbacks.select(action_state.get_selected_entry().value)
          end)

          local methods = function()
            callbacks.methods(action_state.get_selected_entry().value)
          end

          local follow = function()
            callbacks.follow(action_state.get_selected_entry().value)
          end

          map("i", "<tab>", follow)
          map("n", "<tab>", follow)
          map("i", "?", methods)
          map("n", "?", methods)
          return true
        end,
      })
      :find()
end

function M.method_picker(available_methods, callback, opts)
  -- Make table
  local data = {}
  for i, k in ipairs(vim.tbl_keys(available_methods)) do
    data[i] = { value = k, ordinal = k, display = available_methods[k] }
  end
  -- Telescope picker
  pickers
      .new(opts, {
        prompt_title = opts.prompt_title,
        finder = finders.new_table({
          results = data,
          entry_maker = function(entry)
            return entry
          end,
          static = true,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(_)
          actions.select_default:replace(function(_)
            local selection = action_state.get_selected_entry().value
            callback(selection)
          end)
          return true
        end,
      })
      :find()
end

return M
