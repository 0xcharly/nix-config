local bufnr = vim.api.nvim_get_current_buf()

vim.bo[bufnr].comments = ':---,:--'

-- Disable lua_ls's highlight on comment in favor of treesitter's @comment.*
-- LSP's comment highlight override treesitter's, including TODOs and URLs.
vim.api.nvim_set_hl(0, '@lsp.type.comment.lua', {})
-- Disable lua_ls's property highlights. Treesitter provide richer highlights.
vim.api.nvim_set_hl(0, '@lsp.type.property.lua', {})
