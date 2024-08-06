{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (config.settings) isCorpManaged;
in {
  imports = [./nvim/nvim-config.nix];

  home.nvim-config = let
    upkgs = import inputs.nixpkgs-unstable {
      inherit (pkgs) overlays system;
      config.allowUnfreePredicate = pkg:
        !isCorpManaged && builtins.elem (lib.getName pkg) ["copilot.vim"];
    };
  in {
    enable = true;
    src = ./nvim/nvim-config;
    runtime = [./nvim/nvim-runtime];
    pkgs = upkgs;
    plugins =
      (with upkgs.vimPlugins; [
        actions-preview-nvim
        auto-hlsearch-nvim
        catppuccin-nvim
        dial-nvim
        eyeliner-nvim
        fidget-nvim
        gitsigns-nvim
        harpoon2
        lsp-status-nvim
        lspkind-nvim
        lualine-nvim
        nvim-bqf
        nvim-lastplace
        nvim-surround
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects
        nvim-ts-context-commentstring
        nvim-web-devicons
        oil-nvim
        plenary-nvim
        sqlite-lua
        telescope-fzf-native-nvim
        telescope-nvim
        todo-comments-nvim
        trouble-nvim
        vim-matchup
        vim-repeat
        which-key-nvim
        # nvim-cmp and plugins
        nvim-cmp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-cmdline-history
        cmp-nvim-lua
        cmp-nvim-lsp
        cmp-nvim-lsp-document-symbol
        cmp-nvim-lsp-signature-help
        cmp-rg
      ])
      ++ (lib.optionals (!isCorpManaged) [upkgs.vimPlugins.copilot-vim])
      ++ (with upkgs; [
        telescope-manix
        rustaceanvim
      ]);
  };
}
