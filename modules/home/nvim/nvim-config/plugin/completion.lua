-- Exclude keywords/constants from autocomplete
-- https://cmp.saghen.dev/recipes.html#exclude-keywords-constants-from-autocomplete
local function blink_cmp_lsp_filter_out_keywords(_, items)
  return vim.tbl_filter(function(item)
    return item.kind ~= require('blink.cmp.types').CompletionItemKind.Keyword
  end, items)
end

-- Path completion from `cwd` instead of current buffer's directory
-- https://cmp.saghen.dev/recipes.html#path-completion-from-cwd-instead-of-current-buffer-s-directory
local function blink_cmp_path_get_cwd(_)
  return vim.fn.getcwd()
end

require('blink.cmp').setup {
  keymap = {
    preset = 'default',

    ['<C-p>'] = { 'show', 'fallback' },
    ['<C-k>'] = { 'select_prev', 'fallback' },
    ['<C-j>'] = { 'select_next', 'fallback' },

    ['<C-u>'] = { 'scroll_signature_up', 'fallback' },
    ['<C-d>'] = { 'scroll_signature_down', 'fallback' },
  },
  appearance = {
    nerd_font_variant = 'mono',
  },
  completion = {
    documentation = { auto_show = true },
    ghost_text = { enabled = true },
  },
  fuzzy = {
    implementation = 'rust',
    -- Always prioritize exact matches
    -- https://cmp.saghen.dev/recipes.html#always-prioritize-exact-matches
    sorts = {
      'exact',
      -- Then defaults:
      'score',
      'sort_text',
    },
  },
  signature = { enabled = true },
  sources = {
    providers = {
      -- Exclude keywords/constants from autocomplete
      -- https://cmp.saghen.dev/recipes.html#exclude-keywords-constants-from-autocomplete
      lsp = {
        name = 'LSP',
        module = 'blink.cmp.sources.lsp',
        transform_items = blink_cmp_lsp_filter_out_keywords,
      },
      -- Path completion from `cwd` instead of current buffer's directory
      -- https://cmp.saghen.dev/recipes.html#path-completion-from-cwd-instead-of-current-buffer-s-directory
      path = {
        opts = {
          get_cwd = blink_cmp_path_get_cwd,
        },
      },
    },
  },
}
