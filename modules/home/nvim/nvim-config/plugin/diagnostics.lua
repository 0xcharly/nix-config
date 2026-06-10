-- Configure Neovim diagnostic messages

-- Alternatives: { error = '󰅗 󰅙 󰅘 󰅚 󱄊 ', warn = '󰀨 󰗖 󱇎 󱇏 󰲼 ', info = '󰋽 󱔢 ', hint = '󰲽 ' },
local signs = {
  text = {
    [vim.diagnostic.severity.ERROR] = '󰅚 ',
    [vim.diagnostic.severity.WARN] = '󰗖 ',
    [vim.diagnostic.severity.INFO] = '󰋽 ',
    [vim.diagnostic.severity.HINT] = '󰲽 ',
  },
  numhl = {
    [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
    [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
    [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
    [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
  },
}

vim.diagnostic.config {
  -- NOTE: Choose between:
  --   - virtual_text (inline diagnostics)
  --   - virtual_lines (cascading diagnostics)
  virtual_text = {
    spacing = 4,
    prefix = '',
  },
  -- virtual_lines = {
  --   current_line = false, -- Show diagnostics for all lines.
  -- },
  signs = signs,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    border = 'rounded',
    source = true,
  },
}
