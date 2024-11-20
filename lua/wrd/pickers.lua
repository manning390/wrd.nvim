local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewer = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local wrd_actions = require("wrd.actions")

local M = {}

function M.word_picker(data, prompt, opts)
  pickers
      .new(opts, {
        prompt_title = prompt,
        finder = finders.new_table({
          results = data,
          entry_maker = function(entry)
            return vim.tbl_deep_extend("force", { wrd = { opts = opts } }, opts.client.entry_maker(entry))
          end,
          static = true,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewer.new_buffer_previewer({
          define_preview = function(self, entry, _)
            vim.wo[self.state.winid].wrap = true
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, opts.client.previewer(entry) or {})
          end,
          title = "Definition",
        }),
        attach_mappings = function(_, map)
          -- i,n <cr>
          actions.select_default:replace(wrd_actions.wrd_select)
          for mode, mode_mappings in pairs(opts.mappings or {}) do
            for key, action in pairs(mode_mappings) do
              map(mode, key, action)
            end
          end

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
