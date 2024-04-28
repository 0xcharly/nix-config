let
  lua = lua: { __raw = lua; };
in {
  programs.nixvim.plugins.cmp-buffer.enable = true;
  programs.nixvim.plugins.cmp-cmdline.enable = true;
  programs.nixvim.plugins.cmp-nvim-lua.enable = true;
  programs.nixvim.plugins.cmp-nvim-lsp.enable = true;
  programs.nixvim.plugins.cmp-nvim-lsp-document-symbol.enable = true;
  programs.nixvim.plugins.cmp-path.enable = true;

  programs.nixvim.plugins.cmp = {
    enable = true;
    autoEnableSources = false;
    # TODO: enable ciderlsp.
    settings = {
      sources = lua ''
        {
          { name = 'buffer', keyword_length = 3 },
          { name = 'calc' },
          { name = 'nvim_lua' },
          { name = 'nvim_lsp' },
          -- { name = 'nvim_ciderlsp' },
          { name = 'path' },
        }
      '';
      mapping = lua ''
        cmp.mapping.preset.insert {
          ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
          ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert }, { 'i', 'c' }),
          ['<C-m>'] = cmp.mapping.scroll_docs(4),
          ['<C-w>'] = cmp.mapping.scroll_docs(-4),
          ['<C-a>'] = cmp.mapping.abort(),
          ['<C-y>'] = cmp.mapping(
            cmp.mapping.confirm {
              behavior = cmp.ConfirmBehavior.Insert,
              select = true,
            },
            { 'i', 'c' }
          ),
          ['<c-space>'] = cmp.mapping.complete {},
          ['<C-q>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true },
          ['<Tab>'] = cmp.config.disable,
        }
      '';
      sorting.comparators = [
        "require 'cmp.config.compare'.offset"
        "require 'cmp.config.compare'.exact"
        "require 'cmp.config.compare'.score"
        "require 'cmp-under-comparator'.under"
        "require 'cmp.config.compare'.kind"
        "require 'cmp.config.compare'.sort_text"
        "require 'cmp.config.compare'.length"
        "require 'cmp.config.compare'.order"
      ];
      window = lua ''
        {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        }
      '';
    };
    cmdline = {
      "/" = {
        mapping = lua "cmp.mapping.preset.cmdline()";
        sources = [
          { name = "nvim_lsp_document_symbol"; }
          { name = "buffer"; }
        ];
      };
      ":" = {
        mapping = lua "cmp.mapping.preset.cmdline()";
        sources = [
          { name = "path"; }
          {
            name = "cmdline";
            option = { ignore_cmds = [ "Man" "!" ]; };
          }
        ];
      };
    };
    filetype = {
      beancount = {
        sources = [
          {
            name = "beancount";
            option = { account = "delay.beancount"; };
          }
        ];
      };
    };
  };

  programs.nixvim.plugins.lspkind = {
    enable = true;

    cmp = {
      enable = true;
      menu = {
        buffer = ":buf:";
        nvim_lsp = ":lsp:";
        nvim_ciderlsp = ":lsp:";
        path = ":fs:";
      };
    };
  };
}
