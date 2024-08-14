-- Convenience loaders for working with CITC URIs.

local expand_citc_uri = function(uri)
  local path = uri:match('^//(.*)$')

  if path == nil then
    return uri -- Not a CITC URI.
  end

  local username = vim.uv.os_get_passwd().username
  local citc_uri_pattern = '/google/src/cloud/' .. username .. '/([%w_-]+)/(.*)'
  local citc_space, _ = vim.fn.getcwd():match(citc_uri_pattern)
  local citc_space_prefix = '/google/src/cloud/' .. username .. '/' .. citc_space

  if path:startsWith('depot/') then
    path = path:sub(string.len('depot/'))
  else
    citc_space_prefix = citc_space_prefix .. 'google3/'
  end

  return citc_space_prefix .. path
end

vim.api.nvim_create_autocmd({ 'BufReadCmd', 'FileReadCmd' }, {
  pattern = { '//*' },
  callback = function(args)
    vim.cmd.edit(expand_citc_uri(args.match))
  end,
})

vim.api.nvim_create_autocmd({ 'BufWriteCmd', 'FileWriteCmd' }, {
  pattern = { '//*' },
  callback = function(args)
    vim.cmd.write(expand_citc_uri(args.match))
  end,
})
