vim.g.compile_mode = { input_word_completion = true }

-- compile-mode.nvim
vim.keymap.set('n', '<leader>cc', vim.cmd.Compile, { silent = true })
