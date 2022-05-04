# NightVim

NightVim is a configuration framework for Neovim that gives you control

## Installation

1. Check your system vimrc location with `nvim --version`
You should see an section that looks like this
```
   system vimrc file: "$VIM/sysinit.vim"
  fall-back for $VIM: "/usr/share/nvim"
```
2. Clone the repo into your system vimrc directory (In this case `$VIM` that isn't set so `/usr/share/nvim`)
``` 
sudo git clone https://github.com/nyxkrage/nightvim /usr/share/nvim
```

## NightVim manages the boring parts of the configuration

* Bootstrapping package management with [Packer.nvim](https://github.com/wbthomason/packer.nvim)
* LSP, Autocompletion and Snippets with [Neovim LSP Client](https://github.com/neovim/nvim-lspconfig), [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [LuaSnip](https://github.com/L3MON4D3/LuaSnip)
* Smarter Highlighting with [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
* Loading regular colorschemes and colorschemes made with [Colorbuddy.nvim](https://github.com/tjdevries/colorbuddy.nvim) with a unified API
* Easy to use [Lua keymapping wrapper](#keymappings)
* Easily split up your configuration with [protected require](#protected-require)
## User Config Documentation
The user config is your regular neovim init.lua, located in `$HOME/.config/nvim/init.lua`

### User Plugins
Adding plugins is just like how you would use packer manually, except instead of 
using the packer.startup function, you just use the plugins function
```lua
plugins(function(use)
    use 'nyxkrage/henna.nvim' -- Adding a colorscheme, NightVim doesn't ship with anything out of the box
end)
```

### Colorschemes
Switching the colorscheme is done with the color function and supports loading either 
colorbuddy.nvim colorschemes or regular vim colorschemes
```lua
color('henna') -- This is a colorscheme that is built using colorbuddy.nvim

color('gruvbox') -- This is a regular vim colorscheme, that you would usually load with :colorscheme gruvbox
```

### Keymappings
Theres quite a few wrappers for creating keymaps in NightVim, the ones you will mostly be using is `nmap`, `imap` or `vmap`, however just `map` is also available as a lower level wrapper\
And they all follow the same syntax, `(mode)map{"<The keymap you want to bind>", ":Vim command"/function() <lua code> end}`
```lua
-- Map <leader>km in normal mode to run :echo Ran keymap
nmap{'<leader>km', '<CMD>echo Ran keymap'}
-- Map Ctrl+r to a Lua function that prints "ran Ctrl+r" in insert mode in buffer with bufnr 4
imap{'<C-r>', function() print("ran Ctrl+r") end, buffer = 4 }
```
If you want to map to multiple modes you can use the `map` function
```lua
-- Map Ctrl+r in visual and normal mode to print "ran Ctrl+r"
map{'<C-r>', function() print("ran Ctrl+r") end, mode = { 'n', 'v' } }
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
NightVim includes a smaller wrapper, `prequire`
```lua
local telescope = prequire'telescope'
if telescope then
    -- The telescope variable is set to the module, and loaded properly. 
    telescope.setup(...)
end
```
This will also print an error if the module could not be properly loaded, with the location in your config file of where you called `prequire`



## User Config Example

```lua
vim.o.swapfile = false

plugins(function(use)
    use {
        'nvim-telescope/telescope.nvim',
        requires = {
            'nvim-lua/popup.nvim',
            'nvim-lua/plenary.nvim'
        }
    }

    use 'nyxkrage/henna.nvim'
end)

color'henna'

local telescope = prequire'telescope'
if telescope then
    -- We can use normal require here since if 'telescope' loads but 'telescope.builtin' doesn't.
    -- Its a bug in Telescope and not our configuration
    nmap{'<leader>ff', function() require'telescope.builtin'.find_files() end}
end
```
## FAQ

#### Why not use LunarVim

While [LunarVim](https://github.com/LunarVim/LunarVim) is an awesome project, whoever NightVim and LunarVim have 
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
