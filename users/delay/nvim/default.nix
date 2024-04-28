{ inputs, isCorpManaged, ... }:

{ config, pkgs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./autocmd.nix
    ./cmp.nix
    ./keymap.nix
    ./lsp.nix
    ./options.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };

  programs.nixvim = {
    enable = true;

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
      cmp-beancount
      cmp-calc
      cmp-under-comparator
      vim-fish

      (import ./auto-hlsearch.nix { inherit pkgs; })
    ];
 };
}
