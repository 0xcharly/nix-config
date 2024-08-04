local cmd = vim.cmd
local diagnostic = vim.diagnostic
local keymap = vim.keymap

-- Remap for dealing with word wrap.
keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Keymaps for better default experience.
-- See `:help vim.keymap.set()`
keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Helix-inspired keymaps.
keymap.set('n', 'U', '<C-r>', { silent = true }) -- Redo
keymap.set('n', 'gn', cmd.bnext, { silent = true }) -- Goto next buffer
keymap.set('n', 'gp', cmd.bprevious, { silent = true }) -- Goto previous buffer

-- Buffer list navigation
keymap.set('n', '[b', cmd.bprevious, { silent = true, desc = 'previous [b]uffer' })
keymap.set('n', ']b', cmd.bnext, { silent = true, desc = 'next [b]uffer' })
keymap.set('n', '[B', cmd.bfirst, { silent = true, desc = 'first [B]uffer' })
keymap.set('n', ']B', cmd.blast, { silent = true, desc = 'last [B]uffer' })

-- Diagnostic keymaps.
keymap.set('n', '[d', diagnostic.goto_prev, { silent = true })
keymap.set('n', ']d', diagnostic.goto_next, { silent = true })
keymap.set('n', '<Leader>e', diagnostic.open_float, { silent = true })
keymap.set('n', '<Leader>q', diagnostic.setloclist, { silent = true })

-- Make esc leave terminal mode
keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { silent = true })

-- Try and make sure to not mangle space items
keymap.set('t', '<S-Space>', '<Space>', { silent = true })
keymap.set('t', '<C-Space>', '<Space>', { silent = true })

-- To use `Control+{h,j,k,l}` to navigate windows from any mode:
keymap.set('t', '<M-Left>', '<C-\\><C-N><C-w>h', { silent = true })
keymap.set('t', '<M-Down>', '<C-\\><C-N><C-w>j', { silent = true })
keymap.set('t', '<M-Up>', '<C-\\><C-N><C-w>k', { silent = true })
keymap.set('t', '<M-Right>', '<C-\\><C-N><C-w>l', { silent = true })
keymap.set('i', '<C-Left>', '<C-\\><C-N><C-w>h', { silent = true })
keymap.set('i', '<C-Down>', '<C-\\><C-N><C-w>j', { silent = true })
keymap.set('i', '<C-Up>', '<C-\\><C-N><C-w>k', { silent = true })
keymap.set('i', '<C-Right>', '<C-\\><C-N><C-w>l', { silent = true })
keymap.set('n', '<C-Left>', '<C-w>h', { silent = true })
keymap.set('n', '<C-Down>', '<C-w>j', { silent = true })
keymap.set('n', '<C-Up>', '<C-w>k', { silent = true })
keymap.set('n', '<C-Right>', '<C-w>l', { silent = true })

keymap.set('i', '<A-Left>', cmd.tabprev, { silent = true })
keymap.set('i', '<A-Right>', cmd.tabnext, { silent = true })
keymap.set('n', '<A-Left>', cmd.tabprev, { silent = true })
keymap.set('n', '<A-Right>', cmd.tabnext, { silent = true })

keymap.set('v', 'J', ":m '>+1<cr>gv=gv", { silent = true })
keymap.set('v', 'K', ":m '<-2<cr>gv=gv", { silent = true })

keymap.set('n', 'Y', 'yg$', { silent = true })
keymap.set('n', 'n', 'nzzzv', { silent = true })
keymap.set('n', 'N', 'Nzzzv', { silent = true })
keymap.set('n', 'J', 'mzJ`z', { silent = true })
keymap.set('n', '<C-d>', '<C-d>zz', { silent = true })
keymap.set('n', '<C-u>', '<C-u>zz', { silent = true })

-- Better virtual paste.
keymap.set('x', '<Leader>p', '"_dP', { silent = true })
keymap.set('i', '<C-v>', '<C-o>"+p', { silent = true })
keymap.set('c', '<C-v>', '<C-r>+', { silent = true })

-- Better yank.
keymap.set('n', '<Leader>y', '"+y', { silent = true })
keymap.set('v', '<Leader>y', '"+y', { silent = true })
keymap.set('n', '<Leader>Y', '"+Y', { silent = true })

-- Better delete.
keymap.set('n', '<Leader>d', '"_d', { silent = true })
keymap.set('v', '<Leader>d', '"_d', { silent = true })

-- Pane creation.
keymap.set('n', '<Leader>ws', cmd.split, { silent = true })
keymap.set('n', '<Leader>wv', cmd.vsplit, { silent = true })
