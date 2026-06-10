require('oil').setup {
  -- Show files and directories that start with "."
  view_options = { show_hidden = true },
  -- Auto-reload on changes.
  watch_for_changes = true,
}

vim.keymap.set('n', '-', vim.cmd.Oil, { desc = 'open parent directory' })
