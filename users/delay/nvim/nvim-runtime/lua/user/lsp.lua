---@mod user.lsp
---
---@brief [[
---LSP related functions
---@brief ]]

local M = {}

---Gets a 'ClientCapabilities' object, describing the LSP client capabilities
---Extends the object with capabilities provided by plugins.
---@return lsp.ClientCapabilities
function M.make_client_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- Add com_nvim_lsp capabilities.
  capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
  -- Enable preliminary support for workspace/didChangeWatchedFiles.
  capabilities = vim.tbl_deep_extend('keep', capabilities, {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
      configuration = true,
    },
  })
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }
  -- Add any additional plugin capabilities here.
  -- Make sure to follow the instructions provided in the plugin's docs.
  return capabilities
end

-- { error = '󰅗 󰅙 󰅘 󰅚 󱄊 ', warn = '󰀨 󰗖 󱇎 󱇏 󰲼 ', info = '󰋽 󱔢 ', hint = '󰲽 ' },
M.diagnostic_signs = {
  Error = '󰅚 ',
  Warn = '󰗖 ',
  Info = '󰋽 ',
  Hint = '󰲽 ',
}

local preview_location_callback = function(_, result)
  if result == nil or vim.tbl_isempty(result) then
    return nil
  end
  local buf, _ = vim.lsp.util.preview_location(result[1], {})
  if buf then
    local cur_buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].filetype = vim.bo[cur_buf].filetype
  end
end

local peek_definition = function()
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0, 'textDocument/definition', params, preview_location_callback)
end

local peek_type_definition = function()
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0, 'textDocument/typeDefinition', params, preview_location_callback)
end

local keymap = vim.keymap

-- require 'fidget'.setup {}

local code_action = function()
  return require('actions-preview').code_actions()
  -- return vim.lsp.buf.code_action()
end

local go_to_first_import = function()
  vim.lsp.buf.document_symbol {
    on_list = function(lst)
      for _, results in pairs(lst) do
        if type(results) ~= 'table' then
          goto Skip
        end
        for _, result in ipairs(results) do
          if result.kind == 'Module' then
            local lnum = result.lnum
            vim.api.nvim_input("m'")
            vim.api.nvim_win_set_cursor(0, { lnum, 0 })
            return
          end
        end
      end
      ::Skip::
      vim.notify('No imports found.', vim.log.levels.WARN)
    end,
  }
end

---@param filter 'Function' | 'Module' | 'Struct'
local filtered_document_symbol = function(filter)
  vim.lsp.buf.document_symbol()
  vim.cmd.Cfilter(('[[%s]]'):format(filter))
end

local document_functions = function()
  filtered_document_symbol('Function')
end

local document_modules = function()
  filtered_document_symbol('Module')
end

local document_structs = function()
  filtered_document_symbol('Struct')
end

-- Bordered popups.
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

M.on_attach = function(client, bufnr)
  vim.cmd.setlocal('signcolumn=yes')

  local function buf_set_var(...)
    vim.api.nvim_buf_set_var(bufnr, ...)
  end

  vim.bo[bufnr].bufhidden = 'hide'

  buf_set_var('lsp_client_id', client.id)

  local function desc(description)
    return { noremap = true, silent = true, buffer = bufnr, desc = description }
  end

  -- Mappings.
  keymap.set('n', 'gD', vim.lsp.buf.declaration, desc('lsp: go to [D]eclaration'))
  keymap.set('n', 'gd', vim.lsp.buf.definition, desc('lsp: go to [d]efinition'))
  keymap.set('n', '<Leader>gt', vim.lsp.buf.type_definition, desc('lsp: go to [t]ype definition'))
  keymap.set('n', '<Leader>pd', peek_definition, desc('lsp: [p]eek [d]efinition'))
  keymap.set('n', '<Leader>pt', peek_type_definition, desc('lsp: [p]eek [t]ype definition'))
  keymap.set('n', 'gi', vim.lsp.buf.implementation, desc('lsp: go to [i]mplementation'))
  keymap.set('n', '<Leader>gi', go_to_first_import, desc('lsp: [g]o to fist [i]mport'))
  keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, desc('lsp: signature help'))
  keymap.set('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, desc('lsp: [w]orkspace folder [a]dd'))
  keymap.set('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, desc('lsp: [w]orkspace folder [r]emove'))
  keymap.set('n', '<Leader>wl', function()
    -- TODO: Replace this with a Telescope extension?
    vim.print(vim.lsp.buf.list_workspace_folders())
  end, desc('lsp: [w]orkspace folders [l]'))
  keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, desc('lsp: [r]e[n]ame'))
  keymap.set('n', '<Leader>wq', vim.lsp.buf.workspace_symbol, desc('lsp: [w]orkspace symbol [q]uery'))
  keymap.set('n', '<Leader>dd', vim.lsp.buf.document_symbol, desc('lsp: [dd]ocument symbol'))
  keymap.set('n', '<Leader>df', document_functions, desc('lsp: [d]ocument [f]unctions'))
  keymap.set('n', '<Leader>ds', document_structs, desc('lsp: [d]ocument [s]tructs'))
  keymap.set('n', '<Leader>di', document_modules, desc('lsp: [d]ocument modules/[i]mports'))
  if client.name == 'rust-analyzer' then
    keymap.set('n', '<M-CR>', function()
      vim.cmd.RustLsp('codeAction')
    end, desc('rust: code action'))
  else
    keymap.set('n', '<M-CR>', code_action, desc('lsp: code action'))
  end
  keymap.set('n', 'gr', vim.lsp.buf.references, desc('lsp: [g]et [r]eferences'))
  keymap.set({ 'n', 'v' }, '<Leader>f', function()
    vim.lsp.buf.format { async = true }
  end, desc('lsp: [f]ormat buffer'))

  if client.server_capabilities.inlayHintProvider then
    keymap.set('n', '<space>h', function()
      local current_setting = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
      vim.lsp.inlay_hint.enable(not current_setting, { bufnr = bufnr })
    end, desc('lsp: toggle inlay [h]ints'))
  end
end

vim.api.nvim_create_autocmd('LspDetach', {
  group = vim.api.nvim_create_augroup('lsp-detach', {}),
  callback = function(args)
    local group = vim.api.nvim_create_augroup(string.format('lsp-%s-%s', args.buf, args.data.client_id), {})
    pcall(vim.api.nvim_del_augroup_by_name, group)
  end,
})

vim.api.nvim_create_user_command('LspStop', function(kwargs)
  local name = kwargs.fargs[1]
  for _, client in pairs(vim.lsp.get_clients()) do
    if client.name == name then
      vim.lsp.stop_client(client.id)
    end
  end
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_map(function(c)
      return c.name
    end, vim.lsp.get_clients())
  end,
})

return M
