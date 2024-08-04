vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Disable builtin plugins
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1

vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1

vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1

-- Disable unused providers.
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python_provider = 0 -- Python 2

-- Netrw plugin.
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Disable overrides by the VIM runtime ftpugin/python.vim.
-- https://github.com/neovim/neovim/commit/2648c3579a4d274ee46f83db1bd63af38fa9e0a7
vim.g.python_recommended_style = 0

vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = 'yes'
vim.wo.cursorline = true

vim.o.mouse = 'a'

-- Large fold level on startup.
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.o.breakindent = true
vim.o.undofile = true
vim.o.belloff = 'all'

-- Indentation.
vim.o.autoindent = true
vim.o.expandtab = true
vim.o.shiftround = true
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.tabstop = 2
vim.o.textwidth = 80
vim.o.wrap = false

-- Search.
vim.o.incsearch = true
vim.o.ignorecase = true -- Ignore case when searching...
vim.o.smartcase = true -- ... unless there is a capital letter in the query
vim.o.splitright = true -- Prefer windows splitting to the right
vim.o.splitbelow = true -- Prefer windows splitting to the bottom
vim.o.updatetime = 50 -- Make updates happen faster
vim.o.scrolloff = 8 -- Make it so there are always 8 lines below my cursor

vim.opt.formatoptions = vim.opt.formatoptions -- :help formatoptions
  - 't' -- Don't auto-wrap text at 'textwidth'.
  - 'c' -- Don't auto-wrap comments using textwidth.
  + 'r' -- Insert comment leader on newline in Insert mode.
  -- TODO: test drive o=true,/=true.
  + 'o' -- "O" and "o" continue comments...
  + '/' -- ...unless it's a // comment after a statement.
  + 'q' -- Format comments with "gq".
  - 'w' -- Don't use trailing whitespace to detect end of paragraphs.
  - 'a' -- Don't auto-format paragraphs.
  + 'n' -- Detect numbered lists when formatting.
  - '2' -- Use indent from the 1st line of a paragraph.
  - 'v' -- Don't try to be Vi-compatible.
  - 'b' -- Don't try to be Vi-compatible.
  + 'l' -- Don't break long lines in insert mode.
  + 'j' -- Auto-remove comments leader when joining lines.

-- Message output.
vim.opt.shortmess = { -- :help shortmess
  t = true,
  a = true,
  A = true,
  o = true,
  O = true,
  T = true,
  f = true,
  F = true, -- NOTE: this breaks autocommand messages
  s = true,
  c = true,
  W = true,
}

vim.o.grepprg = "rg --hidden --glob '!.git' --no-heading --smart-case --vimgrep --follow $*"
vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }
