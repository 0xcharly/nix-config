vim.lsp.config('*', {
  capabilities = require('user.lsp').make_client_capabilities(),
  root_markers = { '.git', '.jj' },
})
