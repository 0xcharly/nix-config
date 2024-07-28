local api = vim.api

api.nvim_create_user_command('DeleteOtherBufs', '%bd|e#', {})
-- delete current buffer
api.nvim_create_user_command('Q', 'bd % <CR>', {})
api.nvim_create_user_command('W', 'w<CR>', {})
-- delete current buffer (force) -- FIXME
-- api.nvim_create_user_command('Q!', 'bd! % <CR>', {})
