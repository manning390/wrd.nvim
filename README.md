# Wrd.nvim

`wrd.nvim` is an extendable thesaurus and dictionary plugin built on [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim). It leverages [datamuse](https://datamuse.com/) apis and provides multiple functions for finding words related to your query.

## Table of Contents
- [Getting Started](#getting-started)
- [Usage](#usage)

## Getting Started

Requires [Neovim (v0.9.0)](https://github.com/neovim/neovim/releases/tag/v0.9.0), or the lastest neovim nightly commit, for `telescope.nvim`, which is heavily used under the hood. See Telescope installation documentation in case of issues.

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
        {'nvim-telescope/telescope.nvim', tag = '0.1.6'}
      },
      opts = {},
    }
-- plugins/wrd.lua:
return {
    'manning390/wrd.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
        {'nvim-telescope/telescope.nvim', tag = '0.1.6'}
      },
      opts = {},
    }
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'manning390/wrd.nvim'
    requires = { {'nvim-lua/plenary.nvim'}, {'/telescope.nvim', tag = '0.1.6'} }
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.6' }
Plug 'manning390/wrd.nvim'
```

## Usage
If you aren't using the `lazy.nvim` snippet above you'll need to set up the plugin by running the following one time:
```lua
require('wrd').setup({})
```
### Default configuration
These are the default values, set to overwrite:
```lua
{
    client_key = "datamuse", -- Set to target internal client API
    default_method = "means_like", -- Default method if one is not provided, must be available in client API
    commands = true, -- Register the :Wrd command
    client = nil -- Can be set to provide custom client API, if unset, will instance `client` from `client_key`
}
```
### Command
With the default config the `:Wrd` command will get automatically registered.

***Optional arguments and usage may change as I test out this plugin during daily driving***

```
:Wrd
:Wrd sesquipedalian
```
If you pass no arguments you will be promted for a word, autofilled with what's under your cursor. Or you may pass a word directly.

### Chaining
While you are browsing the dictionary responses, you may want to dig deeper or change your query.

- `<tab>` Will take the currently highlighted word within telescope and rerun your method with that word.
- `?` Will prompt you to change methods provided by the client with the current queried word.
