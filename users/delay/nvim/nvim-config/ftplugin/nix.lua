local nixd_cmd = 'nixd'

if vim.fn.executable(nixd_cmd) ~= 1 then
  return
end

local lsp = require('user.lsp')

---@diagnostic disable-next-line: missing-fields
vim.lsp.start {
  name = 'nix',
  cmd = { nixd_cmd, '--inlay-hints', '--semantic-tokens' },
  root_dir = vim.fs.dirname(vim.fs.find({ 'flake.nix', '.git' }, { upward = true })[1]),
  on_attach = lsp.on_attach,
  capabilities = lsp.make_client_capabilities(),
  settings = {
    nixd = {
      formatting = {
        command = { 'alejandra', '-qq' },
      },
    },
  },
}
