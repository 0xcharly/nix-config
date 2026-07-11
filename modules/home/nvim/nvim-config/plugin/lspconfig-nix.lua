vim.lsp.config('nixd', {
  cmd = { 'nixd', '--inlay-hints' },
  settings = {
    nixd = {
      formatting = {
        command = { 'nixfmt' },
      },
    },
  },
})

vim.lsp.enable('nixd')
