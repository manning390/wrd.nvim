# Wrd.nvim

`wrd.nvim` is an extendable thesaurus and dictionary plugin built on [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for neovim. It leverages [datamuse](https://datamuse.com/) apis and provides multiple functions for finding words related to your query.

## Table of Contents
- [Getting Started](#getting-started)
- [Usage](#usage)

## Getting Started

Requires [Neovim v0.10.4](https://github.com/neovim/neovim/releases/tag/v0.10.4) or newer. This matches the minimum supported version for `telescope.nvim` v0.2.0.

### Required dependencies
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is required.
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) is required.

### Installation
Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
{
    'manning390/wrd.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope.nvim', tag = 'v0.2.0' },
    },
    opts = {},
}
-- plugins/wrd.lua:
return {
    'manning390/wrd.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope.nvim', tag = 'v0.2.0' },
    },
    opts = {},
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'manning390/wrd.nvim',
    requires = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope.nvim', tag = 'v0.2.0' },
    },
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': 'v0.2.0' }
Plug 'manning390/wrd.nvim'
```

## Usage
If you aren't using the `lazy.nvim` snippet above, you'll need to run setup at least once to get the `:Wrd` command.

Or you can load the plugin as a telescope extension which will register the telescope flavored commands.

Or you can call the internal methods directly via keymaps.

```lua
require('wrd').setup({}) -- Registers :Wrd
-- or
require('telescope').load_extension('wrd')
-- or
vim.keymap.set('n', 'z/', require('wrd').run, { desc = 'Wrd: Run default query' })
vim.keymap.set('n', 'zm', require('wrd').run_methods, { desc = 'Wrd: List client methods' })
```

### Default configuration
These are the default values, which you can override:
```lua
-- Setup({})
{
    client_key = "datamuse", -- Select the built-in client API
    default_method = "means_like", -- Must be available in the selected client API
    commands = true, -- Register :Wrd; does not affect Telescope exports
    client = nil, -- Provide a custom client API; otherwise `client_key` is used
    rank_jump = {
        enabled = true, -- Treat digits as result ranks instead of fuzzy-search text
        delay_ms = 600, -- Wait briefly for another digit before jumping
    },
    -- Follows Telescope's mapping format
    mappings = {
        i = {
            ["<C-e>"] = require('wrd.actions').wrd_change_word,
            ["<C-j>"] = require('wrd.actions').wrd_cycle_part_of_speech,
            ["<C-y>"] = require('wrd.actions').wrd_copy,
            ["<F1>"] = require('wrd.actions').wrd_help,
            ["<tab>"] = require('wrd.actions').wrd_methods,
            ["/"] = require('wrd.actions').wrd_follow,
        },
        n = {
            ["<C-e>"] = require('wrd.actions').wrd_change_word,
            ["<C-j>"] = require('wrd.actions').wrd_cycle_part_of_speech,
            ["<C-y>"] = require('wrd.actions').wrd_copy,
            ["<F1>"] = require('wrd.actions').wrd_help,
            ["<tab>"] = require('wrd.actions').wrd_methods,
            ["/"] = require('wrd.actions').wrd_follow,
        },
    },
}
```

Mapping overrides are merged per mode and key. You can change one binding
without copying the rest of the default mapping table; set a specific mapping
to `false` to disable it.
### Command
With the default config the `:Wrd` command will get automatically registered.

***Optional arguments and usage may change as I test out this plugin during daily driving***

```
:Wrd
:Wrd sesquipedalian
```

If you loaded the plugin with telescope
```
:Telescope wrd run
:Telescope wrd methods
```
If you pass no arguments you will be prompted for a word, autofilled with what's under your cursor. Or you may pass a word directly.

### Chaining
While you are browsing the dictionary responses, you may want to dig deeper or change your query.

- `/` Will take the currently highlighted word within telescope and rerun your method with that word.
- `<tab>` Will prompt you to change methods provided by the client with the current queried word.
- `<C-e>` Lets you replace the current query word and reruns the same method. Cancelling or submitting the unchanged word leaves the existing picker open.

### Ranked navigation

Datamuse results display their original relevance rank. Type that number while
the picker is open to move the highlight and preview without filtering the
list. A short `Wrd jump: …` indicator appears while the picker waits for another
digit. Press `enter` to resolve a partial number immediately. Pending rank input
expires automatically; Wrd does not override Backspace or Escape, so they keep
their normal Telescope behavior.

Digits are reserved for rank navigation in both insert and normal mode. Set
`rank_jump.enabled = false` if you need digits to be entered into Telescope's
fuzzy-search prompt. A rank hidden by the current fuzzy query is left hidden
and produces an informational message instead of clearing the query.

### Part-of-speech filtering

Press `<C-j>` in the word picker to cycle through All, Nouns, Adjectives,
Verbs, and Adverbs. Categories with no eligible results are skipped. The
results title shows the active filter and its count, such as
`Words · Nouns (35/100)`.

Filtering uses metadata already returned by Datamuse. It does not make another
request, reset fuzzy-search text, or renumber results. Untagged words appear in
All but not in a specific part-of-speech subset.

For separate custom bindings instead of cycling, map any of these public
actions: `wrd_filter_all`, `wrd_filter_nouns`, `wrd_filter_adjectives`,
`wrd_filter_verbs`, or `wrd_filter_adverbs` from `require('wrd.actions')`.

### In-picker help

Press `<F1>` to open Wrd's capabilities window. It shows the active query,
client, method, part-of-speech filter, and the effective Wrd mappings after your
configuration is applied. The overlay deliberately leaves focus in Telescope;
press `<F1>` again to close it. Closing the picker also removes the overlay.
Telescope's generic mapping help remains available separately through `<C-/>`
or `?` in normal mode.

### Selection and copying

Wrd captures the original editing target before Telescope opens. Pressing
`enter` copies the highlighted word to the unnamed (`"`), `+`, and `*`
registers and then applies it as follows:

- On a word, it replaces that complete word.
- On whitespace, it inserts at the original cursor without deleting text.
- From a characterwise visual mapping, it replaces the exact selection.
- From a linewise visual mapping or `:'<,'>Wrd`, it replaces the selected lines.
- For blockwise selections, unmodifiable buffers, or a target that disappeared,
  it copies only and displays an informational message.

Use `<C-y>` to copy and close the picker without editing the original buffer.
Afterward, ordinary `p`/`P` paste after/before the cursor. To replace a different
word manually, use your normal Vim operation, for example `viwp` or
`"_ciw<C-r>"`. The black-hole register in the latter prevents the deleted word
from overwriting Wrd's value in the unnamed register.

For exact characterwise visual replacement, map the Lua entry point in visual
mode:

```lua
vim.keymap.set('x', 'z/', require('wrd').run, { desc = 'Wrd: Replace selection' })
```

### Custom clients

Custom providers use the same ranked picker, previews, navigation, and
selection behavior as Datamuse. A client fetches its native response and
implements `normalize(response)` to return provider-independent results. At a
minimum, each normalized result contains a non-empty `word`; rank, score,
part-of-speech metadata, definitions, provenance, origin, concept, and raw
provider metadata are optional.

You can pass a client directly without placing it under Wrd's module namespace:

```lua
require('wrd').setup({
    default_method = 'lookup',
    client = {
        key = 'my_dictionary',
        available_methods = { lookup = 'Lookup' },
        lookup = function(word)
            return my_dictionary.lookup(word)
        end,
        normalize = function(response)
            return vim.tbl_map(function(item)
                return {
                    word = item.term,
                    definitions = { { text = item.definition } },
                    raw = item,
                }
            end, response.items)
        end,
    },
})
```

Wrd assigns missing ranks from provider order. Part-of-speech filtering is
shown only when the normalized data provides that metadata. See the complete
[client contract](lua/wrd/clients/README.md) for validation and error semantics.

## Development

Run the offline test suite from the repository root:

```sh
./scripts/test
```

The test harness looks for Plenary and Telescope in the standard `lazy.nvim`
data directory. Set `PLENARY_PATH` or `TELESCOPE_PATH` if either dependency is
installed elsewhere.
