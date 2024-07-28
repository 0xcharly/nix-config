-- Configure Neovim diagnostic messages

local function prefix_diagnostic(prefix, diagnostic)
  return string.format(prefix .. ' %s', diagnostic.message)
end

local sign = function(opts)
  vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = '',
  })
end
local diagnostic_signs = require('user.lsp').diagnostic_signs
for name, icon in pairs(diagnostic_signs) do
  sign {
    name = 'DiagnosticSign' .. name,
    text = icon,
  }
end

vim.diagnostic.config {
  virtual_text = {
    spacing = 4,
    prefix = '',
    format = function(diagnostic)
      local severity = diagnostic.severity
      if severity == vim.diagnostic.severity.ERROR then
        return prefix_diagnostic(diagnostic_signs.Error, diagnostic)
      end
      if severity == vim.diagnostic.severity.WARN then
        return prefix_diagnostic(diagnostic_signs.Warn, diagnostic)
      end
      if severity == vim.diagnostic.severity.INFO then
        return prefix_diagnostic(diagnostic_signs.Info, diagnostic)
      end
      if severity == vim.diagnostic.severity.HINT then
        return prefix_diagnostic(diagnostic_signs.Hint, diagnostic)
      end
      return prefix_diagnostic('■', diagnostic)
    end,
  },
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = 'minimal',
    border = 'rounded',
    source = 'if_many',
    header = '',
    prefix = '',
  },
}

local lsp = require('user.lsp')

---@return RustaceanOpts
vim.g.rustaceanvim = function()
  ---@type RustaceanOpts
  local rustacean_opts = {
    server = {
      on_attach = lsp.on_attach,
      capabilities = lsp.make_client_capabilities(),
      default_settings = {
        ['rust-analyzer'] = {
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
            runBuildScripts = true,
          },
          procMacro = {
            enable = true,
            ignored = {
              ['async-trait'] = { 'async_trait' },
              ['napi-derive'] = { 'napi' },
              ['async-recursion'] = { 'async_recursion' },
            },
          },
        },
      },
    },
  }
  return rustacean_opts
end

-- Native plugins
vim.cmd.filetype('plugin', 'indent', 'on')
vim.cmd.packadd('cfilter') -- Allows filtering the quickfix list with :cfdo
