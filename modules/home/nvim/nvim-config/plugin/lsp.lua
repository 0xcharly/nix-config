vim.lsp.config('*', {
  capabilities = require('user.lsp').make_client_capabilities(),
  root_markers = { '.git', '.jj' },
})

-- Treesitter is the single syntax-highlighting source: LSP semantic tokens
-- repaint the same tokens (priority 125 vs 100) with coarser types, so they
-- are disabled globally. Per-attach autostart (lsp/client.lua) checks this.
vim.lsp.semantic_tokens.enable(false)
