-- Enable treesitter highlighting whenever a parser is available.
--
-- The nvim-treesitter plugin (`main` branch) only ships parsers and queries;
-- highlighting must be enabled per-buffer (see `:h treesitter-highlight` and
-- the nvim-treesitter README). Without this autocmd, only the file passed on
-- the command line gets treesitter highlighting (via snacks.quickfile, which
-- only runs before `VimEnter`); every buffer opened later falls back to
-- legacy regex `:syntax`, which lacks language injections (e.g. shell inside
-- Nix strings).

local group = vim.api.nvim_create_augroup('TreesitterHighlight', {})
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = '*',
  callback = function(ev)
    -- Mirror snacks.quickfile's default exclude list: treesitter's LaTeX
    -- highlighting is worse than the legacy syntax file.
    if vim.treesitter.language.get_lang(ev.match) == 'latex' then
      return
    end
    pcall(vim.treesitter.start, ev.buf)
  end,
})
