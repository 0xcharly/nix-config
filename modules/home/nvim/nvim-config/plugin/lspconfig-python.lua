-- Python LSP setup uses both pyright and ruff.
--
-- Pyright for strict type checking. Ruff LSP for linting and formatting.
-- Both advertize great performances.

vim.lsp.config('pyright', {
  settings = {
    pyright = {
      -- Using Ruff's import organizer.
      disableOrganizeImports = true,
    },
    python = {
      analysis = {
        -- Ignore all files for analysis to exclusively use Ruff for linting.
        ignore = { '*' },
        diagnosticSeverityOverrides = {
          -- `analysis.ignore` doesn't silence this one; allow wildcard
          -- imports (e.g. `from build123d import *`). Ruff's F403/F405
          -- are ignored in the ruff config below for the same reason.
          reportWildcardImportFromLibrary = 'none',
        },
      },
    },
  },
})

vim.lsp.config('ruff', {
  init_options = {
    settings = {
      -- Let a project-level ruff.toml/pyproject.toml override these
      -- editor defaults when one exists.
      configurationPreference = 'filesystemFirst',
      lint = {
        -- Allow wildcard imports (e.g. `from build123d import *`):
        -- F403 flags the import line, F405 flags every name that may
        -- originate from it.
        ignore = { 'F403', 'F405' },
      },
    },
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == 'ruff' then
      -- Disable hover in favor of Pyright.
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

vim.lsp.enable { 'pyright', 'ruff' }
