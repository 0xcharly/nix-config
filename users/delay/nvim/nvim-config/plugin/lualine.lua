local section_filename = {
  'filename',
  symbols = {
    modified = '󱇨 ', -- Text to show when the file is modified.
    readonly = '󱀰 ', -- Text to show when the file is non-modifiable or readonly.
    unnamed = '󰡯 ', -- Text to show for unnamed buffers.
    newfile = '󰻭 ', -- Text to show for newly created file before first write
  },
}
local lualine_groups_generator = function(suffix)
  return {
    a = 'LualineA' .. suffix,
    b = 'LualineB' .. suffix,
    c = 'LualineC' .. suffix,
    x = 'LualineX' .. suffix,
    y = 'LualineY' .. suffix,
    z = 'LualineZ' .. suffix,
  }
end
require 'lualine'.setup {
  options = {
    theme = {
      normal = lualine_groups_generator 'Normal',
      insert = lualine_groups_generator 'Insert',
      visual = lualine_groups_generator 'Visual',
      replace = lualine_groups_generator 'Replace',
      command = lualine_groups_generator 'Command',
      inactive = lualine_groups_generator 'Inactive',
    },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { section_filename },
    lualine_c = {
      {
        'lsp_info',
        separator = '‥',
      },
      {
        'diagnostics',
        symbols = {
          error = require 'user.lsp'.diagnostic_signs.Error,
          warn = require 'user.lsp'.diagnostic_signs.Warn,
          info = require 'user.lsp'.diagnostic_signs.Info,
          hint = require 'user.lsp'.diagnostic_signs.Hint,
        },
      },
    },
    lualine_x = {
      {
        'diff',
        symbols = { added = '󱍭 ', modified = '󱨈 ', removed = '󱍪 ' },
        separator = '‥',
      },
      {
        'branch',
        icon = { '', align = 'right' },
      },
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
  inactive_sections = {
    lualine_a = { 'mode' },
    lualine_b = {},
    lualine_c = { section_filename },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {}
  },
}
