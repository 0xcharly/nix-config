# ---[[ LSP config ]]
# -- neovim/nvim-lspconfig
# local lspconfig = require 'lspconfig'
# local cmp_nvim_lsp = require 'cmp_nvim_lsp'

# local user_lsp_utils = require 'user.utils.lsp'

# -- Register servers.
# -- The DartLS server is configured by the flutter-tools plugin.
# -- The RustLS server is configured by the rust-tools plugin.
# user_lsp_utils.clangd_setup(lspconfig, cmp_nvim_lsp)
# user_lsp_utils.lua_ls_setup(lspconfig, cmp_nvim_lsp)
# user_lsp_utils.pylsp_setup(lspconfig, cmp_nvim_lsp)

# if require 'user.utils.company'.is_corporate_host() then
#   user_lsp_utils.ciderlsp_setup(lspconfig, cmp_nvim_lsp)
# end

# user_lsp_utils.ui_tweaks()       -- Adjust UI.
let
  signs = (import ./common.nix).diagnostic_signs;
in {
  programs.nixvim.plugins.lsp = {
    enable = true;

    capabilities = ''
      capabilities = require 'cmp_nvim_lsp'.default_capabilities(capabilities)
      capabilities.textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      }
    '';
    keymaps = {
      diagnostic = {
        "gl" = "open_float";
        "[d" = "goto_prev";
        "]d" = "goto_next";
      };
      lspBuf = {
        "<LocalLeader>k" = "hover";
        "K" = "hover";
        "gd" = "definition";
        "gD" = "declaration";
        "gi" = "implementation";
        "go" = "type_definition";
        "gr" = "references";
        "<LocalLeader>r" = "rename";
        "<LocalLeader>a" = "code_action";
        "<C-k>" = "signature_help";
      };
      extra = [
        {
          key = "<leader>cf";
          action = "function() vim.lsp.buf.format { async = true } end";
          lua = true;
        }
        {
          key = "<LocalLeader>a";
          action = "code_action";
          mode = "x";
        }
      ];
    };

    preConfig = ''
      -- Leading icon on diagnostic virtual text.
      vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          underline = true,
          virtual_text = {
            spacing = 4,
            prefix = ' ',
          },
        })

      -- Bordered popups.
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
        vim.lsp.handlers.hover, { border = 'rounded' })
      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
        vim.lsp.handlers.signature_help, { border = 'rounded' })

      vim.fn.sign_define(hl, { text = '${signs.error}', texthl = 'DiagnosticSignError', numhl = 'DiagnosticSignError' })
      vim.fn.sign_define(hl, { text = '${signs.warn}', texthl = 'DiagnosticSignWarn', numhl = 'DiagnosticSignWarn' })
      vim.fn.sign_define(hl, { text = '${signs.info}', texthl = 'DiagnosticSignInfo', numhl = 'DiagnosticSignInfo' })
      vim.fn.sign_define(hl, { text = '${signs.hint}', texthl = 'DiagnosticSignHint', numhl = 'DiagnosticSignHint' })
    '';

    servers.nixd.enable = true;
    servers.beancount = {
      enable = true;
      extraOptions = {
        init_options = {
          journal_file = "delay.beancount";
        };
      };
    };
    servers.clangd.enable = true;
    servers.lua-ls = {
      enable = true;
      settings = {
        workspace.checkThirdParty = false;
        telemetry.enable = false;
      };
      extraOptions = {
        settings.Lua.format = {
          enable = true;
          defaultConfig = {
            call_arg_parentheses = "remove";
            indent_style = "space";
            quote_style = "single";
          };
        };
      };
    };
    servers.pylsp = {
      enable = true;
      settings = {
        plugins = {
          autopep8.enabled = false;
          pycodestyle = {
            ignore = [ "E126" "W504" ];
            maxLineLength = 100;
            indentSize = 4;
          };
          rope_autoimport.enabled = false;
          yapf.enabled = true;
        };
      };
    };
  };
}
