# NightVim

NightVim is a configuration framework for [Neovim](https://github.com/neovim/neovim) that gives you control.\
Takes care of all the boilerplate you don't want to handle, and lets you write the Neovim configuration you need

## Installation
### User Install

1. Download the `sysinit.lua` file into your neovim config directory as `init.lua`
```
curl https://raw.githubusercontent.com/nyxkrage/NightVim/main/sysinit.lua --create-dirs --output ~/.config/nvim/init.lua
```

### System Install

1. Check your system vimrc location with `nvim --version`
You should see an section that looks like this
```
    system vimrc file: "$VIM/sysinit.vim"
    fall-back for $VIM: "/usr/local/share/nvim"
```
2. Download the `sysinit.lua` and `.vim` files into your system vimrc directory (In this case `$VIM`, that isn't set so `/usr/local/share/nvim`)
``` 
curl "https://raw.githubusercontent.com/nyxkrage/NightVim/main/sysinit.{lua,vim}" --create-dirs --output "/usr/local/share/nvim/sysinit.#1"
```

## NightVim manages the boring parts of the configuration

* Bootstrapping package management with [Packer.nvim](https://github.com/wbthomason/packer.nvim)
* LSP, Autocompletion and Snippets with [Neovim LSP Client](https://github.com/neovim/nvim-lspconfig), [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [LuaSnip](https://github.com/L3MON4D3/LuaSnip) (by default only set up for Lua)
* [Fzf-style](https://github.com/junegunn/fzf) fuzzy file finding with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim)
* Smarter Highlighting with [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
* Loading regular colorschemes and colorschemes made with [Colorbuddy.nvim](https://github.com/tjdevries/colorbuddy.nvim) through a unified API
* Easy to use [Lua keymapping wrapper](#keymappings)
* Easily split up your configuration with [protected require](#protected-require)
## Defaults
* `<leader>w(h|j|k|l)` to switch focus between windows, as an alternative to `C-w (h|j|k|l)`
* `<leader>wq` to close the current window
* `<leader>wsh` and `<leader>wsv` mapped for splitting windows horizontally and vertically, respectively
* `:W` and `:Wq` to use sudo to save root-owned files
* `:Bquit` to close a buffer while keeping your window splits and positions
* Lua LSP pre-configured* to make getting started writing your Neovim config in Neovim as fast as possible

\* You must manually download the [sumneko lua language server]() and place it in your `$PATH`


### Options that differ from regular Neovim

* Search is case insensitive
* Mouse is enabled in normal and visual mode
* Cursorline is enabled, giving a better overview on which line you are on.
* Hybrid line numbers are on, allowing for easy to figure out vim motions when navigating up and down lines, while keeping the absolute line number on the current line to easily know where in the file you are
* 4 space wide tabs
* Pressing tab produces a hardtab rather than 4 spaces
* Keep 4 lines above and below the cursor as much as possible
* Focus the bottom and right window when splitting
* Leader set to space
```
vim.o.ignorecase = true
vim.o.mouse = 'nv'
vim.o.cursorline = true
vim.o.cursorlineopt = 'screenline'
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = false
vim.o.scrolloff = 4
vim.o.splitbelow = true
vim.o.splitright = true
vim.g.mapleader = ' '
```

*Function to revert to Neovim defaults coming soon*

## User Config Documentation

If NightVim is installed in User Mode, your user config will be in `$HOME/.config/nvim/user.lua`\
If NightVim is installed in System Mode, your user user config is your regular neovim init.lua,
located in `$HOME/.config/nvim/init.lua`\
NightVim makes a table called `night` available in the global namespace.

### Night Prelude

If you do not wish to prefix the NightVim functions with `night.` you can either manually bind them to
local variables, or use the `night.prelude()` function \
With the `night.prelude` function, you can optionally include a table of which functions you want export
```lua
-- manually binding to local variables
local prequire = night.prequire
-- using the full prelude
local prequire, nmap, vmap, imap, plugins, color, lsp, command, map, log = night.prelude()
-- using part of the full prelude
local prequire, nmap = night.prelude()
-- optionally only pull nmap and imap out
local nmap, imap = night.prelude{"nmap", "imap"}
```

### User Plugins

Adding plugins is just like how you would use packer manually, except instead of
using the `packer.startup` function, you just use the `night.plugins` function.
```lua
night.plugins(function(use)
    use 'nyxkrage/henna.nvim' -- Adding a colorscheme, NightVim doesn't ship with anything out of the box
end)
```

### Colorschemes

Switching the colorscheme is done with the `night.color` function and supports loading either
colorbuddy.nvim colorschemes or regular vim colorschemes.
```lua
night.color('henna') -- This is a colorscheme that is built using colorbuddy.nvim

night.color('gruvbox') -- This is a regular vim colorscheme, that you would usually load with :colorscheme gruvbox
```

### Keymappings

Theres quite a few wrappers for creating keymaps in NightVim, the ones you will mostly be using is `night.nmap`, `night.imap` or `night.vmap`,
however just `night.map` is also available as a lower level wrapper.\
And they all follow the same syntax, `(mode)map{"<The keymap you want to bind>", ":Vim command"/function() <lua code> end, option = value ... }`
```lua
-- Map <leader>km in normal mode to run :echo Ran keymap
night.nmap{'<leader>km', '<CMD>echo Ran keymap'}
-- Map Ctrl+r to a Lua function that prints "ran Ctrl+r" in insert mode only in buffer 4
night.imap{'<C-r>', function() print("ran Ctrl+r") end, buffer = 4 }
```
If you want to map to multiple modes you can use the `night.map` function
```lua
-- Map Ctrl+r in visual and normal mode to print "ran Ctrl+r"
night.map{'<C-r>', function() print("ran Ctrl+r") end, mode = { 'n', 'v' } }
```

### Protected Require

Instead of loading modules with `pcall`
```lua
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify('Failed to load telescope module', vim.log.levels.ERROR)
else
    telescope.setup(...)
end
```
NightVim includes a smaller wrapper, `night.prequire`
```lua
local telescope = night.prequire'telescope'
if telescope then
    -- The telescope variable is set to the module, and loaded properly. 
    telescope.setup(...)
end
```
This will also print an error if the module could not be properly loaded with the location in your config file of where you called `night.prequire`

## User Config Example

```lua
vim.o.swapfile = false

local plugins, color, prequire = night.prelude{'plugins', 'color', 'prequire'}

plugins(function(use)
    use {
        'TimUntersberger/neogit',
        requires = 'nvim-lua/plenary.nvim'
    }

    use 'nyxkrage/henna.nvim'
end)

color'henna'

local neogit = prequire'neogit'
if neogit then
    neogit.setup{}
    nmap{ '<leader>gg', function() neogit.open() end }
end
```

## FAQ

#### Why not use LunarVim

While [LunarVim](https://github.com/LunarVim/LunarVim) is an awesome project, NightVim and LunarVim have 
very different goals.\
LunarVim aims to be a fully usable IDE out of the box, while NightVim aims to reduce the amount of boilerplate 
you need to have in your config.

#### Why not use Kickstart.nvim

[Kickstart.nvim]() is an awesome learning project and I would absolutely recommend it for anyone new to configuring Neovim with Lua.
It also has very different goals compared to NightVim. 
> The goal of this repo is not to create a neovim configuration framework

From the Kickstart.nvim repo

## License

This project is licensed under the [MIT License](https://choosealicense.com/licenses/mit/)
