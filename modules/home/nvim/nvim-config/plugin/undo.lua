-- Builtin undo-tree.
vim.cmd([[ packadd nvim.undotree ]])
vim.keymap.set('n', '<localleader>u', require('undotree').open)
