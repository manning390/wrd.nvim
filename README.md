
# Wrd.nvim

**This plugin is still under development.**


`wrd.nvim` is an extendable thesaurus and dictionary plugin built on [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim). It leverages [datamuse](https://datamuse.com/) apis and provides multiple functions for finding words related to your query.

## Wrd Table of Contents
- [Getting Started](#getting-started)

## Getting Started

Requires [Neovim (v0.9.0)](https://github.com/neovim/neovim/releases/tag/v0.9.0) or the lastest neovim nightly commit is required for `telescope.nvim` which is heavily used under the hood. See Telescope installation documentation in case of issues.

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
      }
    }
-- plugins/wrd.lua:
return {
    'manning390/wrd.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
        {'nvim-telescope/telescope.nvim', tag = '0.1.6'}
      }
    }
```
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
WIP
