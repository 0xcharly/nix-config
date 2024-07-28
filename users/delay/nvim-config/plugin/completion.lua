local cmp = require('cmp')

local cmp_mapping_next_item =
  cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' })
local cmp_mapping_prev_item =
  cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' })
local cmp_mapping_confirm = cmp.mapping(
  cmp.mapping.confirm {
    behavior = cmp.ConfirmBehavior.Insert,
    select = true,
  },
  { 'i', 'c' }
)

cmp.setup {
  mapping = cmp.mapping.preset.insert {
    ['<C-j>'] = cmp_mapping_next_item,
    ['<C-k>'] = cmp_mapping_prev_item,
    ['<C-S-j>'] = cmp_mapping_next_item,
    ['<C-S-k>'] = cmp_mapping_prev_item,
    ['<C-m>'] = cmp.mapping.scroll_docs(4),
    ['<C-w>'] = cmp.mapping.scroll_docs(-4),
    ['<C-a>'] = cmp.mapping.abort(),
    ['<C-y>'] = cmp_mapping_confirm,
    ['<C-S-y>'] = cmp_mapping_confirm,
    ['<c-space>'] = cmp.mapping.complete {},
    ['<C-q>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true },
    ['<Tab>'] = cmp.config.disable,
  },
  sources = {
    { name = 'nvim_lua' },
    { name = 'nvim_lsp' },
    { name = 'nvim_ciderlsp' },
    { name = 'path' },
    { name = 'buffer', keyword_length = 3 },
  },
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,

      -- Copied from cmp-under; don't need a plugin for this.
      function(entry1, entry2)
        local _, entry1_under = entry1.completion_item.label:find('^_+')
        local _, entry2_under = entry2.completion_item.label:find('^_+')
        entry1_under = entry1_under or 0
        entry2_under = entry2_under or 0
        if entry1_under > entry2_under then
          return false
        elseif entry1_under < entry2_under then
          return true
        end
      end,

      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    format = require('lspkind').cmp_format {
      mode = 'symbol_text',
      preset = 'codicons',
      maxwidth = 50,
      ellipsis_char = '…',
      menu = {
        buffer = ':buf:',
        cmdline = ':cmd:',
        cmdline_history = ':hist"',
        cmp_git = ':git:',
        nvim_ciderlsp = ':cid:',
        nvim_lsp = ':lsp:',
        nvim_lsp_document_symbol = ':lsp"',
        nvim_lsp_signature_help = ':lsp"',
        nvim_lua = ':lua:',
        path = ':fs:',
        rg = ':rg:',
        tmux = ':tmux:',
      },
    },
  },
}

-- Use buffer source for `/`.
cmp.setup.cmdline('/', { sources = { { name = 'buffer' } } })

-- Use cmdline & path source for ':'.
cmp.setup.cmdline(':', {
  sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } }),
})

cmp.setup.filetype('beancount', {
  sources = cmp.config.sources { { name = 'beancount' } },
})
