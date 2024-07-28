local bufnr = vim.api.nvim_get_current_buf()

vim.bo[bufnr].comments = ':---,:--'

local lua_ls_cmd = 'lua-language-server'

-- Check if lua-language-server is available
if vim.fn.executable(lua_ls_cmd) ~= 1 then
  return
end

local root_files = {
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
  '.git',
}

local lsp = require('user.lsp')

vim.lsp.start {
  name = 'lua',
  cmd = { lua_ls_cmd },
  root_dir = vim.fs.dirname(vim.fs.find(root_files, { upward = true })[1]),
  on_attach = lsp.on_attach,
  capabilities = lsp.make_client_capabilities(),
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global, etc.
        globals = {
          'vim',
          'describe',
          'it',
          'assert',
          'stub',
        },
        disable = {
          'duplicate-set-field',
        },
      },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      -- inlay hints (supported in Neovim >= 0.10)
      hint = { enable = true },
      format = {
        enable = true,
        defaultConfig = {
          call_arg_parentheses = 'remove',
          indent_style = 'space',
          quote_style = 'single',
        },
      },
    },
  },
}
