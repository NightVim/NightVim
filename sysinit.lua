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

_G.night = {}

night.map = function(tbl)
	-- Some sane default options
	local opts = { noremap = true, silent = true }
	-- Dont want these named fields on the options table
	local mode = tbl['mode']
	tbl['mode'] = nil

	for k, v in pairs(tbl) do
		if tonumber(k) == nil then
			opts[k] = v
		end
	end

	vim.keymap.set(mode, tbl[1], tbl[2], opts)
end

night.nmap = function(tbl)
	tbl['mode'] = 'n'
	night.map(tbl)
end

night.vmap = function(tbl)
	tbl['mode'] = 'v'
	night.map(tbl)
end

night.imap = function(tbl)
	tbl['mode'] = 'i'
	night.map(tbl)
end

night.command = function(tbl)
	local opts = {}

	for k, v in pairs(tbl) do
		if tonumber(k) == nil then
			opts[k] = v
		end
	end
	vim.api.nvim_create_user_command(tbl[1], tbl[2], opts)
end

night.log = {
	info = function(msg)
		vim.notify(msg, vim.log.levels.INFO)
	end,
	warn = function(msg)
		vim.notify(msg, vim.log.levels.WARN)
	end,
	err = function(msg)
		vim.notify(msg, vim.log.levels.ERROR)
	end,
}

night.prequire = function(m)
	local ok, err = pcall(require, m)
	if not ok then
		night.log.warn('[prequire|' .. debug.getinfo(2,'S').short_src .. '] Failed to load module `' .. m .. '`')
		return nil, err
	end
	return err
end

local packer_bootstrap = nil
local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  packer_bootstrap = vim.fn.system{'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path}
end
vim.api.nvim_command 'packadd packer.nvim'

night.plugins = function(fun)
	local packer = night.prequire'packer'
	if packer then
		packer.startup(function(use)
			-- Plugin Manager
			use 'wbthomason/packer.nvim'

			-- LSP, Completion, and Snippets
			use {
				'neovim/nvim-lspconfig',
				'hrsh7th/nvim-cmp',
				'hrsh7th/cmp-nvim-lsp',
				'hrsh7th/cmp-buffer',
				'hrsh7th/cmp-cmdline',
				'hrsh7th/cmp-path',
				'L3MON4D3/LuaSnip',
				'saadparwaiz1/cmp_luasnip',
			}

			-- Treesitter
			use {
				'nvim-treesitter/nvim-treesitter',
				'nvim-treesitter/playground',
			}

			-- Whichkey
			use {
				"folke/which-key.nvim",
			}

			-- Colors
			use {
				'tjdevries/colorbuddy.nvim'
			}

			-- Fuzzy finding
			use {
				'nvim-lua/popup.nvim',
				'nvim-lua/plenary.nvim',
				'nvim-telescope/telescope.nvim',
				{ 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
				'nvim-telescope/telescope-file-browser.nvim',
			}

			if fun then
				fun(use)
			end

			if packer_bootstrap then
				packer.sync()
			end
		end)
	end
end

night.lsp = function(server, opts)
	local lspconfig = night.prequire'lspconfig'
	if lspconfig then
		lspconfig[server].setup(opts)
	end
end

night.on_attach = function(client, bufnr)
	night.log.info('[LSP] Attaching `' .. client.name .. '` to buffer: ' .. bufnr)

	vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

night.color = function(theme)
	local colorbuddy = night.prequire'colorbuddy'
	if colorbuddy then
		local ok = pcall(colorbuddy.colorscheme, theme)
		if not ok then
			vim.log.err('[COLOR] Colorscheme `' .. theme .. '` is not a valid colorschem, make sure you ran :PackerSync and restarted Neovim')
		end
	else
		vim.log.err('[COLOR] Colorbuddy could not be loaded, please try running :PackerSync and restarting Neovim')
	end
end

night.prelude = function(tbl)
	if tbl == nil then
		-- Table is not nil so only export the wanted parts of the prelude
		tbl = {
			'prequire',
			'nmap',
			'vmap',
			'imap',
			'plugins',
			'color',
			'lsp',
			'command',
			'map',
			'log',
			'userconfig'
		}
	end
	local returns = {}
	for _, val in pairs(tbl) do
		table.insert(returns, night[val])
	end
	return unpack(returns)
end


local function init(autocmd_opts)
	if autocmd_opts then
		vim.api.nvim_del_autocmd(autocmd_opts.id)
	end

	-- Set up Lua LSP with proper globals for the neovim Lua API and the sysinit globals
	local runtime_path = vim.split(package.path, ';')
	table.insert(runtime_path, "lua/?.lua")
	table.insert(runtime_path, "lua/?/init.lua")
	table.insert(runtime_path, vim.env.VIM .. "/sysinit.lua")
	night.lsp('sumneko_lua', {
		on_attach = night.on_attach,
		flags = {
			debounce_text_changes = 150,
		},
		settings = {
			Lua = {
				runtime = {
					version = 'LuaJIT',
					path = runtime_path,
				},
				diagnostics = {
					globals = {
						'vim',
						'night'
					},
				},
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = {
					enable = false,
				},
			},
		},
	})

	-- Set up Which Key
	local whichkey = night.prequire'which-key'
	if whichkey then
		whichkey.setup{}
	end

	-- Set up nvim-cmp for autocompletion
	-- cmp setup
	local cmp = night.prequire'cmp'
	if cmp then
		cmp.setup({
			snippet = {
				expand = function(args)
					require('luasnip').lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
				['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
				['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
				['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
				['<C-e>'] = cmp.mapping({
					i = cmp.mapping.abort(),
					c = cmp.mapping.close(),
				}),
				['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
			}),
			sources = cmp.config.sources({
				{ name = 'nvim_lsp' },
				{ name = 'luasnips' },
				{ name = 'buffer' }
			})
		})
	end

	-- Register the Telescope file browser, and fzf sorter
	local telescope = night.prequire'telescope'
	if telescope then
		telescope.setup {
			extensions = {
				fzf = {
					-- false will only do exact matching
					fuzzy = true,
					-- override the generic sorter
					override_generic_sorter = true,
					-- override the file sorter
					override_file_sorter = true,
					-- or "ignore_case" or "respect_case"
					-- the default case_mode is "smart_case"
					case_mode = "smart_case",
				}
			}
		}
		telescope.load_extension'file_browser'
		telescope.load_extension'fzf'
	end

	local filename = debug.getinfo(1, 'S').source:match("^.*[/\\](.*.lua)$")
	if filename == 'init.lua' then
		night.userconfig = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') ..'user.lua'
	elseif filename == 'sysinit.lua' then
		night.userconfig = vim.env.HOME .. '/.config/nvim/init.lua'
	else
		night.userconfig = debug.getinfo(1, 'S').short_src
	end

	-- N: NightVim
	night.nmap{'<leader>nr', '<CMD>luafile ' .. night.userconfig .. '<CR>'}
	night.nmap{'<leader>ne', '<CMD>edit ' .. night.userconfig .. '<CR>'}

	vim.api.nvim_create_autocmd({"User"}, {
		pattern = { "PackerComplete"},
		callback = function()
			if packer_bootstrap then
				vim.cmd('luafile ' .. night.userconfig)
				packer_bootstrap = nil
			end
			vim.cmd'mode'
		end
	})

	if filename == 'init.lua' then
		local ok, err = pcall(require, 'user')
		if not ok then
			night.log.warn('Error detected while proccessing' .. debug.getinfo(1, 'S').source:sub(2):match('(.*/)') ..'user.lua\n' .. err:sub(3))
		end
	elseif filename ~= 'sysinit.lua' then
		night.log.err'[NightVim] The NightVim config file should either be `~/.config/nvim/init.lua` or `$VIM/sysinit.lua`'
	end
end

vim.api.nvim_create_autocmd({"User"}, {
	pattern = { "PackerComplete"},
	callback = init
})

if packer_bootstrap then
	night.plugins()
else
	init()
end

-- Write file as sudo and reload the file
night.command{"W", 'execute ":silent w !sudo tee % > /dev/null" | :edit!'}
-- Write file as sudo and quit
night.command{"Wq", 'execute ":silent w !sudo tee % > /dev/null" | :q'}
-- Quit buffer without changing windows
night.command{"Bquit", 'setl bufhidden=delete | bnext!'}

-- Setup mappings to navigate between windows without having to use C-w
-- W: Window
night.nmap{'<leader>wh', '<C-W>h'}
night.nmap{'<leader>wj', '<C-W>j'}
night.nmap{'<leader>wk', '<C-W>k'}
night.nmap{'<leader>wl', '<C-W>l'}
-- W: Window Split
night.nmap{'<leader>wsv', '<CMD>vsplit<CR>'}
night.nmap{'<leader>wsh', '<CMD>split<CR>'}
night.nmap{'<leader>wq', '<CMD>quit<CR>'}

