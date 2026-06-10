-- Keep this at the very top. Changing this will erase all <Leader> and
-- <LocalLeader> bindings already defined.
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Native plugins
vim.cmd.filetype('plugin', 'indent', 'on')

-- New UI opt-in
require('vim._core.ui2').enable {}
