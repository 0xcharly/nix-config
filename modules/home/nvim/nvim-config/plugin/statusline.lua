local modes = {
  ['v'] = 'VISUAL',
  ['V'] = 'VISUAL',
  [''] = 'VISUAL',
  ['s'] = 'SELECT',
  ['S'] = 'SELECT',
  [''] = 'SELECT',
  ['i'] = 'INSERT',
  ['ic'] = 'INSERT',
  ['R'] = 'REPLACE',
  ['Rv'] = 'REPLACE',
  ['c'] = 'COMMAND',
  ['cv'] = 'COMMAND',
  ['ce'] = 'COMMAND',
  ['t'] = 'TERMINAL',
}
local default_mode_icon = 'NORMAL'

local function mode(winid)
  if winid == vim.api.nvim_get_current_win() then
    local current_mode = vim.api.nvim_get_mode().mode
    return string.format('%s', modes[current_mode] or default_mode_icon):upper()
  end

  return default_mode_icon
end

local function filename(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return '-- Empty --'
  end

  local fname = vim.fn.fnamemodify(name, ':t')
  if fname == '' then
    return '-- No Name --'
  end

  return fname
end

local function location(bufnr)
  if vim.api.nvim_get_option_value('filetype', { buf = bufnr }) == 'alpha' then
    return ''
  end
  return '%l:%c %P'
end

local function bufinfo(bufnr)
  if vim.api.nvim_get_option_value('modified', { buf = bufnr }) then
    return '[+]'
  end
  if
    not vim.api.nvim_get_option_value('modifiable', { buf = bufnr })
    or vim.api.nvim_get_option_value('readonly', { buf = bufnr })
  then
    return '[RO]'
  end
  return ''
end

local function lspinfo(bufnr)
  local function count(severity)
    return vim.tbl_count(vim.diagnostic.get(bufnr, { severity = severity }))
  end

  local function render(severity, hl, sign)
    local severity_count = count(severity)
    if severity_count == 0 then
      return ''
    end
    return '%#DiagnosticSign' .. hl .. '#' .. sign .. severity_count .. ' '
  end

  return table.concat {
    render(vim.diagnostic.severity.ERROR, 'Error', '󰅚 '),
    render(vim.diagnostic.severity.WARN, 'Warn', '󰗖 '),
    render(vim.diagnostic.severity.INFO, 'Info', '󰋽 '),
    render(vim.diagnostic.severity.HINT, 'Hint', '󰲽 '),
  }
end

local function GenerateFocusedStatusline(winid, bufnr)
  return table.concat {
    '%#StatusLineFocusedPrimary#',
    ' ',
    mode(winid),
    '%#StatusLineFocusedSecondary#',
    '  ',
    filename(bufnr),
    '  ',
    location(bufnr),
    ' ',
    bufinfo(bufnr),
    '%=',
    lspinfo(bufnr),
  }
end

local function GenerateUnfocusedStatusline(winid, bufnr)
  return table.concat {
    '%#StatusLineUnfocusedPrimary#',
    ' ',
    mode(winid),
    '%#StatusLineUnfocusedSecondary#',
    '  ',
    filename(bufnr),
    '  ',
    location(bufnr),
    ' ',
    bufinfo(bufnr),
  }
end

function GenerateStatusline(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  if winid == vim.api.nvim_get_current_win() then
    return GenerateFocusedStatusline(winid, bufnr)
  end
  return GenerateUnfocusedStatusline(winid, bufnr)
end

---@diagnostic disable-next-line: unused-local
function RefreshStatusline(_event)
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if vim.api.nvim_buf_is_valid(bufnr) then
      local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
      if buftype == '' or buftype == 'file' or buftype == 'terminal' then
        vim.api.nvim_set_option_value('statusline', GenerateStatusline(winid), { scope = 'local', win = winid })
      end
    end
  end

  vim.api.nvim_command([[ redrawstatus ]])
end

local statusline_group = vim.api.nvim_create_augroup('StatusLineRefreshGroup', {})

vim.api.nvim_create_autocmd({
  'BufEnter',
  'BufModifiedSet',
  'BufLeave',
  'BufNew',
  'BufNewFile',
  'BufReadPost',
  'BufWinEnter',
  'BufWritePost',
  'DiagnosticChanged',
  'ModeChanged',
  'TabEnter',
  'TermOpen',
  'VimResized',
  'WinEnter',
  'WinLeave',
}, {
  callback = vim.schedule_wrap(RefreshStatusline),
  group = statusline_group,
})
