if not vim.g.vscode then

  -- folke/trouble.nvim
  vim.keymap.set('<leader>xx', function() require 'trouble'.toggle() end)
  vim.keymap.set('<leader>xw', function() require 'trouble'.toggle 'workspace_diagnostics' end)
  vim.keymap.set('<leader>xd', function() require 'trouble'.toggle 'document_diagnostics' end)
  vim.keymap.set('<leader>xq', function() require 'trouble'.toggle 'quickfix' end)
  vim.keymap.set('<leader>xl', function() require 'trouble'.toggle 'loclist' end)
  vim.keymap.set('gR', function() require 'trouble'.toggle 'lsp_references' end)

  -- nvim-telescope/telescope.nvim
  require 'telescope'.setup {
    defaults = {
      prompt_prefix = '   ',
      entry_prefix = '   ',
      selection_caret = '  ',
      layout_strategy = 'flex',

      file_previewer = require 'telescope.previewers'.vim_buffer_cat.new,
      grep_previewer = require 'telescope.previewers'.vim_buffer_vimgrep.new,
      qflist_previewer = require 'telescope.previewers'.vim_buffer_qflist.new,

      mappings = {
        n = { ['<c-t>'] = require 'trouble.providers.telescope'.open_with_trouble },
        i = {
          ['<c-t>'] = require 'trouble.providers.telescope'.open_with_trouble,
          ['<esc>'] = require 'telescope.actions'.close,
          ['<C-x>'] = false,
          ['<C-q>'] = require 'telescope.actions'.send_to_qflist,
          ['<CR>'] = require 'telescope.actions'.select_default,
        },
      },
    },
  }

  require 'telescope'.load_extension 'fzf'
  vim.keymap.set('<LocalLeader>f', function() require 'user.utils.telescope'.pickers.find_files() end)
  vim.keymap.set(
    '<LocalLeader><Space>',
    function()
      vim.fn.system [[ git rev-parse --is-inside-work-tree ]]
      if vim.v.shell_error == 0 then
        require 'user.utils.telescope'.pickers.git_files()
      else
        require 'user.utils.telescope'.pickers.find_files()
      end
    end
  )
  vim.keymap.set('<LocalLeader>g', function() require 'user.utils.telescope'.pickers.live_grep() end)
  vim.keymap.set(
    '<LocalLeader>.',
    function()
      local opts = { cwd = '~/.config' }
      if vim.fn.executable 'rg' > 0 then
        opts.find_command = { 'rg', '--ignore', '--hidden', '--files' }
      elseif vim.fn.executable 'fd' > 0 then
        opts.find_command = { 'fd', '--type', 'f', '--strip-cwd-prefix' }
      end
      require 'user.utils.telescope'.pickers.find_files(opts)
    end
  )
  vim.keymap.set('<LocalLeader>b', function() require 'user.utils.telescope'.buffers() end)
  vim.keymap.set('<LocalLeader>j', function() require 'user.utils.telescope'.pickers.jumplist() end)
  vim.keymap.set('<LocalLeader>h', function() require 'user.utils.telescope'.pickers.highlights() end)
  vim.keymap.set('<LocalLeader>s', function() require 'user.utils.telescope'.pickers.lsp_document_symbols() end)
  vim.keymap.set('<LocalLeader>S', function() require 'user.utils.telescope'.pickers.lsp_dynamic_workspace_symbols() end)
  vim.keymap.set('<LocalLeader>d', function() require 'user.utils.telescope'.pickers.diagnostics() end)
  vim.keymap.set('<LocalLeader>/', function() require 'user.utils.telescope'.pickers.find_files() end)
  vim.keymap.set('<LocalLeader>?', function() require 'user.utils.telescope'.pickers.help_tags() end)
  vim.keymap.set('<LocalLeader>tm', function() require 'user.utils.telescope'.pickers.man_pages() end)
  vim.keymap.set('<LocalLeader>*', function() require 'user.utils.telescope'.pickers.grep_string() end)

  ---[[ Languages/syntaxes ]]
  -- nvim-treesitter/nvim-treesitter
  -- build = ':TSUpdate',
  ---@diagnostic disable: missing-fields
  require 'nvim-treesitter.configs'.setup {
    ensure_installed = {
      'bash',
      'beancount',
      'c',
      -- 'comment', -- NOTE: Huge performance drop when using `comment`.
      'cpp',
      'dart',
      'diff',
      'fish',
      'java',
      'json',
      'kotlin',
      'lua',
      'markdown',
      'markdown_inline',
      'python',
      'regex',
      'rst',
      'rust',
      'sql',
      'vimdoc',
      'yaml',
    },
    sync_install = false,       -- Install parsers synchronously (only applied to `ensure_installed`)
    auto_install = false,       -- Automatically install missing parsers when entering buffer
    highlight = { enable = true },
    -- Disabled for Dart and Python until #4945 is resolved.
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/4945
    -- https://www.reddit.com/r/nvim/comments/147u8ln/nvim_lags_when_a_dart_file_is_opened/
    indent = { enable = true, disable = { 'dart', 'python' } },
    incremental_selection = { enable = false },
    textobjects = {
      select = { enable = false },
      move = { enable = false },
    },
  }

  ---[[ Completion engine ]]
  -- hrsh7th/nvim-cmp
  local cmp = require 'cmp'

  cmp.setup {
    mapping = cmp.mapping.preset.insert {
      ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
      ['<C-m>'] = cmp.mapping.scroll_docs(4),
      ['<C-w>'] = cmp.mapping.scroll_docs(-4),
      ['<C-a>'] = cmp.mapping.abort(),
      ['<C-y>'] = cmp.mapping(
        cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        },
        { 'i', 'c' }
      ),
      ['<c-space>'] = cmp.mapping.complete {},
      ['<C-q>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true },
      ['<Tab>'] = cmp.config.disable,
    },
    sources = {
      { name = 'nvim_lua' },
      { name = 'nvim_lsp' },
      { name = 'nvim_ciderlsp' },
      { name = 'path' },
      { name = 'luasnip' },
      { name = 'buffer',       keyword_length = 3 },
    },
    sorting = {
      comparators = {
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        cmp.config.compare.score,

        -- Copied from cmp-under; don't need a plugin for this.
        function(entry1, entry2)
          local _, entry1_under = entry1.completion_item.label:find '^_+'
          local _, entry2_under = entry2.completion_item.label:find '^_+'
          entry1_under = entry1_under or 0
          entry2_under = entry2_under or 0
          if entry1_under > entry2_under then
            return false
          elseif entry1_under < entry2_under then
            return true
          end
        end,

        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
    snippet = {
      expand = function(args) require 'luasnip'.lsp_expand(args.body) end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    formatting = {
      format = require 'lspkind'.cmp_format {
        mode = 'symbol_text',
        preset = 'codicons',
        maxwidth = 50,
        ellipsis_char = '…',
        menu = {
          buffer = ' (buf)',
          nvim_lsp = ' (lsp)',
          nvim_lua = ' (lua)',
          nvim_ciderlsp = ' (cid)',
        },
      },
    },
  }

  -- Use buffer source for `/`.
  cmp.setup.cmdline('/', { sources = { { name = 'buffer' } } })

  -- Use cmdline & path source for ':'.
  cmp.setup.cmdline(':', {
    sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } }),
  })

  cmp.setup.filetype('beancount', {
    sources = cmp.config.sources { { name = 'beancount' } },
  })

  ---[[ LSP config ]]
  -- neovim/nvim-lspconfig
  local lspconfig = require 'lspconfig'
  local cmp_nvim_lsp = require 'cmp_nvim_lsp'

  local user_lsp_utils = require 'user.utils.lsp'

  -- Register servers.
  -- The DartLS server is configured by the flutter-tools plugin.
  -- The RustLS server is configured by the rust-tools plugin.
  user_lsp_utils.clangd_setup(lspconfig, cmp_nvim_lsp)
  user_lsp_utils.lua_ls_setup(lspconfig, cmp_nvim_lsp)
  user_lsp_utils.pylsp_setup(lspconfig, cmp_nvim_lsp)

  if require 'user.utils.company'.is_corporate_host() then
    user_lsp_utils.ciderlsp_setup(lspconfig, cmp_nvim_lsp)
  end

  user_lsp_utils.ui_tweaks()       -- Adjust UI.

  -- stevearc/conform.nvim
  vim.keymap.set(
  -- Customize or remove this keymap to your liking
    '<leader>cf',
    function()
      require 'conform'.format { async = true, lsp_fallback = true }
    end
  )
  -- Everything in opts will be passed to setup()
  require 'conform'.setup {
    -- Define your formatters
    formatters_by_ft = {
      -- lua = { 'stylua' },
      -- python = { 'isort', 'black' },
      -- javascript = { { 'prettierd', 'prettier' } },
    },
    -- Customize formatters
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2' },
      },
    },
  }
end

vim.g.loaded_health = 1
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_rplugin = 1
vim.g.loaded_shada = 1
vim.g.loaded_spellfile = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor = 1
vim.g.loaded_zipPlugin = 1

-- Netrw plugin.
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Disable overrides by the VIM runtime ftpugin/python.vim.
-- https://github.com/neovim/neovim/commit/2648c3579a4d274ee46f83db1bd63af38fa9e0a7
vim.g.python_recommended_style = 0

-- Mouse support.
vim.o.mouse = 'a'

-- No horizontal scroll.
vim.keymap.set('n', '<ScrollWheelLeft>', '<Nop>', { silent = true })
vim.keymap.set('n', '<ScrollWheelRight>', '<Nop>', { silent = true })

-- Window appearance.
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = 'yes'
vim.wo.cursorline = true

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
vim.o.ignorecase = true                       -- Ignore case when searching...
vim.o.smartcase = true                        -- ... unless there is a capital letter in the query
vim.o.splitright = true                       -- Prefer windows splitting to the right
vim.o.splitbelow = true                       -- Prefer windows splitting to the bottom
vim.o.updatetime = 50                         -- Make updates happen faster
vim.o.scrolloff = 8                           -- Make it so there are always 8 lines below my cursor

vim.opt.formatoptions = vim.opt.formatoptions -- :h fo
  - 't'        -- Don't auto-wrap text at 'textwidth'.
  - 'c'        -- Don't auto-wrap comments using textwidth.
  + 'r'        -- Insert comment leader on newline in Insert mode.
  -- TODO: test drive o=true,/=true.
  + 'o'        -- "O" and "o" continue comments...
  + '/'        -- ...unless it's a // comment after a statement.
  + 'q'        -- Format comments with "gq".
  - 'w'        -- Don't use trailing whitespace to detect end of paragraphs.
  - 'a'        -- Don't auto-format paragraphs.
  + 'n'        -- Detect numbered lists when formatting.
  - '2'        -- Use indent from the 1st line of a paragraph.
  - 'v'        -- Don't try to be Vi-compatible.
  - 'b'        -- Don't try to be Vi-compatible.
  + 'l'        -- Don't break long lines in insert mode.
  + 'j'        -- Auto-remove comments leader when joining lines.

-- Message output.
vim.opt.shortmess = {
  t = true, -- truncate file messages at start
  a = true, -- ignore annoying save file messages
  A = true, -- ignore annoying swap file messages
  o = true, -- file-read message overwrites previous
  O = true, -- file-read message overwrites previous
  T = true, -- truncate non-file messages in middle
  f = true, -- (file x of x) instead of just (x of x
  F = true, -- Don't give file info when editing a file, NOTE: this breaks autocommand messages
  s = true,
  c = true,
  W = true, -- Dont show [w] or written when writing
}

-- Keymaps for better default experience.
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap.
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Use faster grep alternatives if possible.
if vim.fn.executable 'rg' > 0 then
  vim.o.grepprg = [[rg --hidden --glob '!.git' --no-heading --smart-case --vimgrep --follow $*]]
  vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }
elseif vim.fn.executable 'ag' > 0 then
  vim.o.grepprg = [[ag --nogroup --nocolor --vimgrep]]
  vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }
end

-- [[ Flash on yank ]]
-- See `:help vim.highlight.on_yank()`
local yank_group = vim.api.nvim_create_augroup('HighlightYank', {})
vim.api.nvim_create_autocmd('TextYankPost', {
  group = yank_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank {
      higroup = 'IncSearch',
      timeout = 40,
    }
  end,
})

-- [[ Remove trailing whitespaces ]]
local whitespace_group = vim.api.nvim_create_augroup('WhitespaceGroup', {})
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = whitespace_group,
  pattern = '*',
  command = '%s/\\s\\+$//e',
})

-- [[ Key bindings ]]
local keymap_opts = { silent = true }

-- Helix-inspired keymaps.
vim.keymap.set('n', 'U', '<C-r>', keymap_opts)           -- Redo
vim.keymap.set('n', 'gn', ':bnext<CR>', keymap_opts)     -- Goto next buffer
vim.keymap.set('n', 'gp', ':bprevious<CR>', keymap_opts) -- Goto previous buffer

-- Diagnostic keymaps.
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, keymap_opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, keymap_opts)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, keymap_opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, keymap_opts)

-- Make esc leave terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', keymap_opts)

-- Try and make sure to not mangle space items
vim.keymap.set('t', '<S-Space>', '<Space>', keymap_opts)
vim.keymap.set('t', '<C-Space>', '<Space>', keymap_opts)

-- To use `Control+{h,j,k,l}` to navigate windows from any mode:
vim.keymap.set('t', '<M-Left>', '<C-\\><C-N><C-w>h', keymap_opts)
vim.keymap.set('t', '<M-Down>', '<C-\\><C-N><C-w>j', keymap_opts)
vim.keymap.set('t', '<M-Up>', '<C-\\><C-N><C-w>k', keymap_opts)
vim.keymap.set('t', '<M-Right>', '<C-\\><C-N><C-w>l', keymap_opts)
vim.keymap.set('i', '<C-Left>', '<C-\\><C-N><C-w>h', keymap_opts)
vim.keymap.set('i', '<C-Down>', '<C-\\><C-N><C-w>j', keymap_opts)
vim.keymap.set('i', '<C-Up>', '<C-\\><C-N><C-w>k', keymap_opts)
vim.keymap.set('i', '<C-Right>', '<C-\\><C-N><C-w>l', keymap_opts)
vim.keymap.set('n', '<C-Left>', '<C-w>h', keymap_opts)
vim.keymap.set('n', '<C-Down>', '<C-w>j', keymap_opts)
vim.keymap.set('n', '<C-Up>', '<C-w>k', keymap_opts)
vim.keymap.set('n', '<C-Right>', '<C-w>l', keymap_opts)

vim.keymap.set('i', '<A-Left>', '<cmd>tabprev<cr>', keymap_opts)
vim.keymap.set('i', '<A-Right>', '<cmd>tabnext<cr>', keymap_opts)
vim.keymap.set('n', '<A-Left>', '<cmd>tabprev<cr>', keymap_opts)
vim.keymap.set('n', '<A-Right>', '<cmd>tabnext<cr>', keymap_opts)

vim.keymap.set('n', '<LocalLeader>pv', vim.cmd.Ex)

vim.keymap.set('v', 'J', ":m '>+1<cr>gv=gv", keymap_opts)
vim.keymap.set('v', 'K', ":m '<-2<cr>gv=gv", keymap_opts)

vim.keymap.set('n', 'Y', 'yg$', keymap_opts)
vim.keymap.set('n', 'n', 'nzzzv', keymap_opts)
vim.keymap.set('n', 'N', 'Nzzzv', keymap_opts)
vim.keymap.set('n', 'J', 'mzJ`z', keymap_opts)
vim.keymap.set('n', '<C-d>', '<C-d>zz', keymap_opts)
vim.keymap.set('n', '<C-u>', '<C-u>zz', keymap_opts)

-- Better virtual paste.
vim.keymap.set('x', '<LocalLeader>p', '"_dP', keymap_opts)
vim.keymap.set('i', '<C-v>', '<C-o>"+p', keymap_opts)
vim.keymap.set('c', '<C-v>', '<C-r>+', keymap_opts)

-- Better yank.
vim.keymap.set('n', '<LocalLeader>y', '"+y', keymap_opts)
vim.keymap.set('v', '<LocalLeader>y', '"+y', keymap_opts)
vim.keymap.set('n', '<LocalLeader>Y', '"+Y', keymap_opts)

-- Better delete.
vim.keymap.set('n', '<LocalLeader>d', '"_d', keymap_opts)
vim.keymap.set('v', '<LocalLeader>d', '"_d', keymap_opts)

-- Pane creation.
vim.keymap.set('n', '<LocalLeader>ws', '<cmd>split<cr>', keymap_opts)
vim.keymap.set('n', '<LocalLeader>wv', '<cmd>vsplit<cr>', keymap_opts)
