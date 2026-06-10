vim.lsp.config('lua_ls', {
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
})

vim.lsp.enable('lua_ls')
