{ inputs, ... }:

{ config, helpers, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;

  common = import ./common.nix;

  isCorpManaged = lib.filesystem.pathIsDirectory "/google/src/cloud/delay/";
in {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./autocmd.nix
    ./keymap.nix
    ./options.nix
  ];

  home.sessionVariables.EDITOR = "nvim";

  # programs.neovim = {
  #   enable = true;
  #   viAlias = true;
  #   vimAlias = true;
  #   defaultEditor = true;
  #   withPython3 = true;
  #   plugins = with pkgs; [
  #     customVim.vim-fish
  #     customVim.vim-fugitive
  #     customVim.vim-pgsql
  #     customVim.vim-zig
  #     customVim.vim-nix
  #     customVim.nvim-auto-hlsearch
  #     {
  #       plugin = customVim.nvim-catppuccin;
  #       config = ''
  #         packadd! catppuccin
  #         lua << END
  #         vim.o.termguicolors = true
  #         require 'catppuccin'.setup { transparent_background = true }
  #         vim.cmd [[colorscheme catppuccin-mocha]]
  #         END
  #       '';
  #     }
  #     customVim.nvim-comment
  #     customVim.nvim-conform
  #     customVim.nvim-gitsigns
  #     customVim.nvim-lastplace
  #     customVim.nvim-lualine
  #     customVim.nvim-lspconfig
  #     customVim.nvim-neodev
  #     customVim.nvim-nonicons
  #     customVim.nvim-plenary
  #     customVim.nvim-rustacean
  #     customVim.nvim-surround
  #     customVim.nvim-telescope
  #     customVim.nvim-treesitter
  #     customVim.nvim-treesitter-textobjects
  #     customVim.nvim-trouble
  #     customVim.nvim-web-devicons
  #     customVim.vim-markdown
  #   ] ++ (lib.optionals (!isCorpManaged) [
  #     customVim.vim-copilot
  #   ]);

  programs.nixvim = mkIf isLinux {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    luaLoader.enable = true;

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        term_colors = true;
      };
    };
    plugins.comment.enable = true;
    plugins.conform-nvim = import ./conform-nvim.nix;
    plugins.copilot-vim.enable = !isCorpManaged;
    plugins.fugitive.enable = true;
    plugins.gitsigns.enable = true;
    plugins.lastplace.enable = true;
    plugins.lualine = import ./lualine.nix;
    plugins.nix.enable = true;
    plugins.rustaceanvim.enable = true;
    plugins.surround.enable = true;
    plugins.telescope = import ./telescope.nix { inherit config; };
    plugins.treesitter = import ./treesitter.nix;
    plugins.trouble.enable = true;
    plugins.zig.enable = true;

    extraPlugins = with pkgs.vimPlugins; [
      vim-fish

      (import ./auto-hlsearch.nix { inherit pkgs; })

      # TODO: cmp
      # TODO: lspconfig
    ];
 };
}
