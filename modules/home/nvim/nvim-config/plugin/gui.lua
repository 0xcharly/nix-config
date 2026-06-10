-- Use the system's monospace font.
vim.o.guifont = 'monospace:h12'

-- Neovide-specific options.
if vim.g.neovide then
  vim.opt.winblend = 100
  vim.opt.pumblend = 100
  vim.g.neovide_floating_blur_amount_x = 30
  vim.g.neovide_floating_blur_amount_y = 30

  vim.g.neovide_padding_top = 12
  vim.g.neovide_padding_bottom = 12
  vim.g.neovide_padding_right = 12
  vim.g.neovide_padding_left = 12

  vim.g.neovide_cursor_animation_length = 0.02
  vim.g.neovide_cursor_short_animation_length = 0.01
  vim.g.neovide_cursor_trail_size = 1

  vim.g.neovide_scroll_animation_far_lines = 0
  vim.g.neovide_scroll_animation_length = 0.1
end
