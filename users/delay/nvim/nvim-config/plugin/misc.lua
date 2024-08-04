-- let sqlite.lua (which some plugins depend on) know where to find sqlite
vim.g.sqlite_clib_path = require 'luv'.os_getenv 'LIBSQLITE'
