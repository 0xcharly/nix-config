vim.lsp.config('nixd', {
  cmd = { 'nixd', '--inlay-hints', '--semantic-tokens' },
  settings = {
    nixd = {
      formatting = {
        command = { 'nixfmt' },
      },
    },
  },
})

vim.lsp.enable('nixd')
