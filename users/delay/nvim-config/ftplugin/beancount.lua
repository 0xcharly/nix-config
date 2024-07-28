local beancount_cmd = 'beancount-language-server'

if vim.fn.executable(beancount_cmd) ~= 1 then
  return
end

local lsp = require('user.lsp')

---@diagnostic disable-next-line: missing-fields
vim.lsp.start({
  name = 'beancount',
  cmd = { beancount_cmd },
  root_dir = vim.fs.dirname(vim.fs.find({ 'delay.beancount' }, { upward = true })[1]),
  single_file_support = true,
  init_options = {
    journal_file = '~/beancount/delay.beancount',
  },
  settings = {},
  on_attach = lsp.on_attach,
  capabilities = lsp.make_client_capabilities(),
}, {
  reuse_client = function(client, conf)
    return client.name == conf.name and client.config.root_dir == conf.root_dir
  end,
})

-- require 'telescope'.load_extension 'beancount'
--
-- vim.keymap.set('n', '<Leader>mc', '<cmd>%s/txn/*/gc<CR>', {
--   desc = 'beancount-nvim: mark transactions as reconciled',
--   noremap = true,
--   silent = true,
-- })
-- vim.keymap.set('n', '<Leader>mt', function()
--   require 'telescope'.extensions.beancount.copy_transactions(require 'telescope.themes'.get_ivy {})
-- end, {
--   desc = 'Telescope: beancount: copy beancount transactions',
--   noremap = true,
--   silent = true,
-- })
