local M = {}

local function GetBufferName(bufnr)
  local name = vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or ''

  if name == '' then
    return '-- Empty --'
  end

  if vim.api.nvim_get_option_value('buftype', { buf = bufnr }) == 'terminal' then
    return 'term'
  end

  return vim.fn.fnamemodify(name, ':t')
end

local function array_filter(arr_in, predicate)
  local arr_out = {}

  for _, value in ipairs(arr_in) do
    if predicate(value) then
      table.insert(arr_out, value)
    end
  end

  return arr_out
end

local function GenerateTabLine()
  local tabline_buf = ''
  local current_tab = vim.fn.tabpagenr()
  local total_tabs = vim.fn.tabpagenr('$')

  for tabnr = 1, total_tabs do
    local buflist = array_filter(vim.fn.tabpagebuflist(tabnr), function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
      end
      local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
      return buftype == '' or buftype == 'file' or buftype == 'terminal'
    end)

    local fname = ''
    if #buflist ~= 0 then
      fname = GetBufferName(buflist[1])

      if #buflist > 1 then
        fname = fname .. ' (+' .. tostring(#buflist) .. ')'
      end
    else
      fname = '-- Empty --'
    end

    if tabnr == current_tab then
      tabline_buf = tabline_buf .. '%#TabLineSel#' .. fname .. '%#TabLine#'
    else
      tabline_buf = tabline_buf .. fname
    end

    if tabnr ~= total_tabs then
      tabline_buf = tabline_buf .. ' '
    end
  end

  return tabline_buf .. '%#TabLineFill#%T'
end

function M.RefreshTabLine()
  vim.api.nvim_set_option_value('tabline', GenerateTabLine(), { scope = 'global' })
  vim.api.nvim_command([[ redrawtabline ]])
end

vim.opt.tabline = '%!v:lua.GenerateTabLine()'

local tabline_group = vim.api.nvim_create_augroup('TabLineRefreshGroup', {})

vim.api.nvim_create_autocmd({
  'BufDelete',
  'BufEnter',
  'BufNew',
  'BufNewFile',
  'BufReadPost',
  'BufWinEnter',
  'BufWinLeave',
  'BufWipeout',
  'BufWritePost',
  'TabEnter',
  'TabNew',
  'TabClosed',
  'TermClose',
  'TermOpen',
  'VimResized',
  'WinClosed',
  'WinEnter',
  'WinLeave',
}, {
  callback = vim.schedule_wrap(M.RefreshTabLine),
  group = tabline_group,
})

return M
