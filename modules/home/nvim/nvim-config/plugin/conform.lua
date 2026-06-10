local conform = require('conform')

conform.setup {
  formatters_by_ft = {
    c = { 'clang-format' },
    cpp = { 'clang-format' },
    elixir = { 'mix' },
    javascript = { 'prettier' },
    json = { 'yq' },
    just = { 'just' },
    kdl = { 'kdlfmt' },
    lua = { 'stylua' },
    python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
    toml = { 'taplo' },
    typescript = { 'prettier' },
    yaml = { 'yq' },
    -- Use the "_" filetype to run formatters on filetypes that don't
    -- have other formatters configured.
    ['_'] = { 'trim_whitespace', 'trim_newlines', lsp_format = 'last' },
  },
  formatters = {
    ['clang-format'] = {
      prepend_args = { '-style=file', '-fallback-style=Google' },
    },
  },
  notify_on_error = false,
}

vim.keymap.set('', '<LocalLeader>f', function()
  conform.format({ async = true }, function(err, did_edit)
    if not err and not did_edit then
      local mode = vim.api.nvim_get_mode().mode
      if vim.startswith(string.lower(mode), 'v') then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
      end
    end
  end)
end, { desc = '[F]ormat buffer' })

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
