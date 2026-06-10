-- let sqlite.lua (which some plugins depend on) know where to find sqlite
---@diagnostic disable-next-line: missing-parameter
vim.g.sqlite_clib_path = require('luv').os_getenv('LIBSQLITE_CLIB_PATH')
