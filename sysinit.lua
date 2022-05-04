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

_G.map = function(tbl)
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

_G.nmap = function(tbl)
	tbl['mode'] = 'n'
	map(tbl)
end

_G.vmap = function(tbl)
	tbl['mode'] = 'v'
	map(tbl)
end

_G.imap = function(tbl)
	tbl['mode'] = 'i'
	map(tbl)
end

_G.command = function(tbl)
	local opts = {}

	for k, v in pairs(tbl) do
		if tonumber(k) == nil then
			opts[k] = v
		end
	end
	vim.api.nvim_create_user_command(tbl[1], tbl[2], opts)
end

_G.log = {
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

_G.prequire = function(m)
	local ok, err = pcall(require, m)
	if not ok then
		log.err('[prequire|' .. debug.getinfo(2,'S').short_src .. '] Failed to load module `' .. m .. '`')
		return nil, err
	end
	return err
end

_G.lsp = function(server, opts)
	local lspconfig = prequire'lspconfig'
	if lspconfig then
		lspconfig[server].setup(opts)
	end
end

_G.on_attach = function(client, bufnr)
	log.info('[LSP] Attaching `' .. client.name .. '` to buffer: ' .. bufnr)

	vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
end

_G.color = function(theme)
	local colorbuddy = prequire'colorbuddy'
	if colorbuddy then
		local ok = pcall(colorbuddy.colorscheme, theme)
		if ok then
			return
		end
	end
	vim.api.nvim_command('colorscheme ' .. theme)
end

local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  _G.packer_bootstrap = vim.fn.system{'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path}
end
vim.api.nvim_command 'packadd packer.nvim'

_G.plugins = function(fun)
	local packer = prequire'packer'
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
				config = function()
				end,
			}

			-- Treesitter
			use {
				'nvim-treesitter/nvim-treesitter',
				'nvim-treesitter/playground',
			}

			-- Whichkey
			use {
				"folke/which-key.nvim",
				config = function() require("which-key").setup {} end,
			}

			-- Colors
			use {
				'tjdevries/colorbuddy.nvim'
			}

			fun(use)

			if packer_bootstrap then
				packer.sync()
			end
		end)
	end
end


-- Write file as sudo and reload the file
command{"W", 'execute ":silent w !sudo tee % > /dev/null" | :edit!'}
-- Write file as sudo and quit
command{"Wq", 'execute ":silent w !sudo tee % > /dev/null" | :q'}
-- Quit buffer without changing windows
command{"Bquit", 'setl bufhidden=delete | bnext!'}

-- Setup mappings to navigate between windows without having to use C-w
-- W: Window
nmap{'<leader>wh', '<C-W>h'}
nmap{'<leader>wj', '<C-W>j'}
nmap{'<leader>wk', '<C-W>k'}
nmap{'<leader>wl', '<C-W>l'}
-- W: Window Split
nmap{'<leader>wsv', '<CMD>vsplit<CR>'}
nmap{'<leader>wsh', '<CMD>split<CR>'}
nmap{'<leader>wq', '<CMD>quit<CR>'}


-- Setup Lua LSP with proper globals for the neovim Lua API and the sysinit globals
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
table.insert(runtime_path, vim.env.VIM .. "/sysinit.lua")
lsp('sumneko_lua', {
	on_attach = on_attach,
	capabilities = capabilities,
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
					'log',
					'prequire',
					'plugins',
					'color',
					'lsp',
					'on_attach',
					'map',
					'nmap',
					'vmap',
					'imap',
					'command',
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
