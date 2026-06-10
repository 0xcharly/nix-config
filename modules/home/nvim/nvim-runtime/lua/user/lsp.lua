--- @mod user.lsp

local M = {}

-- { error = '󰅗 󰅙 󰅘 󰅚 󱄊 ', warn = '󰀨 󰗖 󱇎 󱇏 󰲼 ', info = '󰋽 󱔢 ', hint = '󰲽 ' },
M.diagnostic_signs = {
  Error = '󰅚 ',
  Warn = '󰗖 ',
  Info = '󰋽 ',
  Hint = '󰲽 ',
}

--- Gets a 'ClientCapabilities' object, describing the LSP client capabilities
--- Extends the object with capabilities provided by plugins.
--- @return lsp.ClientCapabilities
function M.make_client_capabilities()
  return require('blink.cmp').get_lsp_capabilities {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
      configuration = true,
    },
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  }
end

-- grn in Normal mode maps to vim.lsp.buf.rename()
-- grr in Normal mode maps to vim.lsp.buf.references()
-- gri in Normal mode maps to vim.lsp.buf.implementation()
-- gO in Normal mode maps to vim.lsp.buf.document_symbol()
-- gra in Normal and Visual mode maps to vim.lsp.buf.code_action()
-- grt in Normal mode maps to vim.lsp.buf.type_definition()
-- grx in Normal mode maps to vim.lsp.codelens.run()
-- CTRL-S in Insert and Select mode maps to vim.lsp.buf.signature_help()
-- [d and ]d move between diagnostics in the current buffer ([D jumps to the first diagnostic, ]D jumps to the last)

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('K', vim.lsp.buf.hover, 'Hover Documentation')

    -- Displays signature information about the symbol under the cursor in a
    -- floating window.
    map('grk', vim.lsp.buf.signature_help, 'Signature Help')

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is defined, etc.
    map('grd', Snacks.picker.lsp_definitions, 'Goto Definition(s)')

    -- Find references for the word under your cursor.
    map('grr', Snacks.picker.lsp_references, 'Goto References')

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual implementation.
    map('gri', Snacks.picker.lsp_implementations, 'Goto Implementation')

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    map('gO', function()
      Snacks.picker.lsp_symbols { layout = { reverse = false } }
    end, 'Document Symbols')

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    map('grO', Snacks.picker.lsp_workspace_symbols, 'Workspace Symbols')

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- NOTE: This is not Goto Definition, this is Goto Declaration.
    -- For example, in C this would take you to the header.
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_declaration) then
      map('grD', vim.lsp.buf.declaration, 'Goto Declaration')
    end

    -- The following code creates a keymap to toggle inlay hints in your code,
    -- if the language server you are using supports them
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('gih', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, 'Toggle Inlay Hints')
    end
  end,
})

return M
