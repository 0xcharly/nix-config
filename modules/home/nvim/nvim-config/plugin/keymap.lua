-- Keymaps for better default experience.
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Helix-inspired keymaps.
vim.keymap.set('n', 'U', '<C-r>', { silent = true }) -- Redo
vim.keymap.set('n', 'gn', vim.cmd.bnext, { silent = true }) -- Goto next buffer
vim.keymap.set('n', 'gp', vim.cmd.bprevious, { silent = true }) -- Goto previous buffer

-- Diagnostic keymaps.
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { silent = true })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { silent = true })

-- Make esc leave terminal mode.
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { silent = true })

-- Try and make sure to not mangle space items.
vim.keymap.set('t', '<S-Space>', '<Space>', { silent = true })
vim.keymap.set('t', '<C-Space>', '<Space>', { silent = true })

-- Use `Control+{←↓↑→}` to navigate windows from any mode.
vim.keymap.set({ 'i', 't' }, '<C-Left>', '<C-\\><C-N><C-w>h', { silent = true })
vim.keymap.set({ 'i', 't' }, '<C-Down>', '<C-\\><C-N><C-w>j', { silent = true })
vim.keymap.set({ 'i', 't' }, '<C-Up>', '<C-\\><C-N><C-w>k', { silent = true })
vim.keymap.set({ 'i', 't' }, '<C-Right>', '<C-\\><C-N><C-w>l', { silent = true })
vim.keymap.set('n', '<C-Left>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<C-Down>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<C-Up>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<C-Right>', '<C-w>l', { silent = true })

-- Use `Alt+{jk} to navigate between tabs.
vim.keymap.set({ 'i', 'n' }, '<A-j>', vim.cmd.tabprev, { silent = true })
vim.keymap.set({ 'i', 'n' }, '<A-k>', vim.cmd.tabnext, { silent = true })

-- Better defaults.
vim.keymap.set('n', 'n', 'nzzzv', { silent = true })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true })
vim.keymap.set('n', 'J', 'mzJ`z', { silent = true })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { silent = true })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { silent = true })

-- Better virtual paste.
vim.keymap.set('x', '<leader>p', '"_dP', { silent = true })
vim.keymap.set('i', '<C-v>', '<C-o>"+p', { silent = true })
vim.keymap.set('c', '<C-v>', '<C-r>+', { silent = true })

-- Better yank.
vim.keymap.set('n', 'Y', 'yg$', { silent = true })
vim.keymap.set('n', '<leader>Y', '"+Y', { silent = true })
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { silent = true })

-- Better delete.
vim.keymap.set({ 'n', 'v' }, '<leader>d', '"_d', { silent = true })

-- Pane creation.
vim.keymap.set('n', '<leader>wh', vim.cmd.split, { silent = true })
vim.keymap.set('n', '<leader>wv', vim.cmd.vsplit, { silent = true })

-- Virtual mode line movements.
vim.keymap.set('v', 'J', ":m '>+1<cr>gv=gv", { silent = true })
vim.keymap.set('v', 'K', ":m '<-2<cr>gv=gv", { silent = true })
