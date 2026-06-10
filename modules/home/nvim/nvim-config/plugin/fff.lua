require('fff').setup {
  prompt = '   ',
  title = 'Files',
  keymaps = {
    move_up = { '<Up>', '<C-k>' },
    move_down = { '<Down>', '<C-j>' },
  },
  hl = { cursor = 'Visual' },
  -- preview = { enabled = false },
}

vim.keymap.set('n', 'ff', function()
  require('fff').find_files()
end, { desc = '[f]iles' })

vim.keymap.set('n', 'fg', function()
  require('fff').live_grep { title = 'Pattern', grep = { modes = { 'fuzzy', 'plain', 'regex' } } }
end, { desc = '[g]rep' })

-- IMPORTANT NOTE: if deleting this in the future, also cleanup the
-- `InactiveDisableCursorLine` auto-group in `autocmd.lua`.
