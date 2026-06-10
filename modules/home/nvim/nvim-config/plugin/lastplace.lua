vim.opt.viewoptions = "cursor" -- what gets saved in the session
vim.api.nvim_create_autocmd("BufWinLeave", { command = "silent! mkview" })
vim.api.nvim_create_autocmd("BufWinEnter", { command = "silent! loadview" })
