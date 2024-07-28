local telescope = require('telescope')
local actions = require('telescope.actions')

local function lazy_require(moduleName)
  return setmetatable({}, {
    __index = function(_, key)
      return function(...)
        local module = require(moduleName)
        return module[key](...)
      end
    end,
  })
end

local builtin = lazy_require('telescope.builtin')

local extensions = setmetatable({}, {
  __index = function(_, key)
    if telescope.extensions[key] then
      return telescope.extensions[key]
    end
    telescope.load_extension(key)
    return telescope.extensions[key]
  end,
})

-- Common opts for all pickers.
local pickers_defaults = { previewer = false, disable_devicons = true }

local pickers = setmetatable({}, {
  __index = function(_, key)
    if builtin[key] == nil then
      error('Invalid key, please check :h telescope.builtin')
      return
    end
    return function(opts)
      opts = vim.tbl_extend('keep', opts or {}, pickers_defaults)
      builtin[key](opts)
    end
  end,
})

-- Fall back to find_files if not in a git repo
local project_files = function()
  local opts = {} -- define here if you want to define something
  local ok = pcall(pickers.git_files, opts)
  if not ok then
    pickers.find_files(opts)
  end
end

local function grep_current_file_type(func, extra_args)
  local current_file_ext = vim.fn.expand('%:e')
  local additional_vimgrep_arguments = {}
  if current_file_ext ~= '' then
    additional_vimgrep_arguments = vim.list_extend(extra_args or {}, {
      '--type',
      current_file_ext,
    })
  end
  local conf = require('telescope.config').values
  func {
    vimgrep_arguments = vim.tbl_flatten {
      conf.vimgrep_arguments,
      additional_vimgrep_arguments,
    },
  }
end

local function grep_string_current_file_type()
  grep_current_file_type(pickers.grep_string)
end

local function live_grep_current_file_type()
  grep_current_file_type(pickers.live_grep)
end

local function fuzzy_grep(opts)
  opts = vim.tbl_extend('error', opts or {}, { search = '', prompt_title = 'Fuzzy grep' })
  pickers.grep_string(opts)
end

local function fuzzy_grep_current_file_type()
  grep_current_file_type(fuzzy_grep)
end

-- vim.keymap.set('n', '<Leader>f', pickers.find_files)
-- vim.keymap.set('n', '<Leader><Space>', project_files, { desc = 'telescope: project files git' })
-- vim.keymap.set('n', '<Leader>b', buffers)
-- vim.keymap.set('n', '<Leader>j', pickers.jumplist)
-- vim.keymap.set('n', '<Leader>h', pickers.highlights)
-- vim.keymap.set('n', '<Leader>s', pickers.lsp_document_symbols)
-- vim.keymap.set('n', '<Leader>S', pickers.lsp_dynamic_workspace_symbols)
-- vim.keymap.set('n', '<Leader>d', pickers.diagnostics)
-- vim.keymap.set('n', '<Leader>/', pickers.find_files)
-- vim.keymap.set('n', '<Leader>?', pickers.help_tags)
-- vim.keymap.set('n', '<Leader>tm', pickers.man_pages)
-- vim.keymap.set('n', '<Leader>*', pickers.grep_string)
-- vim.keymap.set('n', '<Leader>g', pickers.live_grep)

vim.keymap.set('n', '<Leader>ts', pickers.live_grep, { desc = '[t]elescope: live grep (regex [s]earch)' })
vim.keymap.set('n', '<C-g>', function()
  local conf = require('telescope.config').values
  pickers.live_grep {
    vimgrep_arguments = table.insert(conf.vimgrep_arguments, '-F'),
  }
end, { desc = 'telescope: live grep (no regex)' })
vim.keymap.set('n', '<Leader>tf', fuzzy_grep, { desc = '[t]elescope: [f]uzzy grep' })
vim.keymap.set('n', '<M-f>', fuzzy_grep_current_file_type, { desc = 'telescope: fuzzy grep filetype' })
vim.keymap.set('n', '<M-g>', live_grep_current_file_type, { desc = 'telescope: live grep filetype' })
vim.keymap.set('n', '<Leader>t*', grep_string_current_file_type, { desc = '[t]elescope: grep string [*] filetype' })
vim.keymap.set('n', '<Leader>*', pickers.grep_string, { desc = 'telescope: grep string' })
vim.keymap.set('n', '<Leader>t?', pickers.help_tags, { desc = '[t]elescope: help [?] tags' })
vim.keymap.set('n', '<Leader>tg', project_files, { desc = '[t]elescope: project files [g]it' })
vim.keymap.set('n', '<Leader>t.n', function()
  pickers.git_files { cwd = '~/code/nixos-config' }
end)
vim.keymap.set('n', '<Leader>t.v', function()
  pickers.git_files { cwd = '~/code/nix-config-nvim' }
end)
vim.keymap.set('n', '<Leader>tc', pickers.quickfix, { desc = '[t]elescope: quickfix [c] list' })
vim.keymap.set('n', '<Leader>tq', pickers.command_history, { desc = '[t]elescope: command [q] history' })
vim.keymap.set('n', '<Leader>tl', pickers.loclist, { desc = '[t]elescope: [l]oclist' })
vim.keymap.set('n', '<Leader>tr', pickers.registers, { desc = '[t]elescope: [r]egisters' })
vim.keymap.set('n', '<Leader>td', pickers.diagnostics, { desc = '[t]elescope: [d]iagnostics' })
vim.keymap.set('n', '<Leader>ty', function()
  extensions.yank_history.yank_history()
end, { desc = '[t]elescope: [y]ank history' })
vim.keymap.set('n', '<Leader>tbb', pickers.buffers, { desc = '[t]elescope: [bb]uffers' })
vim.keymap.set('n', '<Leader>tbf', pickers.current_buffer_fuzzy_find, { desc = '[t]elescope: [b]uffer [f]uzzy find' })
vim.keymap.set('n', '<Leader>ts', pickers.lsp_document_symbols, { desc = '[t]elescope: lsp document [s]ymbols' })
vim.keymap.set(
  'n',
  '<Leader>tw',
  pickers.lsp_dynamic_workspace_symbols,
  { desc = '[t]elescope: lsp dynamic [w]orkspace symbols' }
)
vim.keymap.set('n', '<Leader>th', function()
  extensions.harpoon.marks()
end, { desc = '[t]elescope: [h]arpoon marks' })

require('telescope').setup {
  defaults = {
    prompt_prefix = ': ',
    entry_prefix = '   ',
    selection_caret = '  ',
    layout_strategy = 'flex',

    file_previewer = require('telescope.previewers').vim_buffer_cat.new,
    grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
    qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,

    mappings = {
      n = {
        q = actions.close,
        ['<C-t>'] = require('trouble.sources.telescope').open,
      },
      i = {
        ['<C-t>'] = require('trouble.sources.telescope').open,
        ['<ESC>'] = actions.close,
        ['<C-x>'] = false,
        ['<C-q>'] = actions.send_to_qflist,
        ['<C-l>'] = actions.send_to_loclist,
        ['<CR>'] = actions.select_default,
      },
    },
    history = {
      path = vim.fn.stdpath('data') .. '/telescope_history.sqlite3',
      limit = 1000,
    },
    set_env = { ['COLORTERM'] = 'truecolor' },
    vimgrep_arguments = {
      'rg',
      '-L',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
    },
  },
}

require('telescope').load_extension('fzf')
