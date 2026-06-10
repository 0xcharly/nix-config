vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = false,
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
      },
      rustfmt = {
        rangeFormatting = {
          enable = true,
        },
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
})

vim.lsp.enable('rust_analyzer')
