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
        catppuccin-nvim
        gitsigns-nvim
        harpoon2
        lualine-nvim
        nvim-lastplace
        nvim-surround
        (nvim-treesitter.withPlugins (p:
          with p; [
            awk
            bash
            beancount
            c
            cmake
            comment
            cpp
            css
            csv
            dart
            devicetree
            dhall
            diff
            dot
            fish
            gitcommit
            gitignore
            ini
            java
            json
            just
            kotlin
            lua
            make
            markdown
            markdown_inline
            nix
            objc
            python
            rust
            ssh_config
            starlark
            toml
            yaml
            zig
          ]))
        oil-nvim
        plenary-nvim
        sqlite-lua
        telescope-fzf-native-nvim
        telescope-nvim
        todo-comments-nvim
        # nvim-cmp and plugins
        nvim-cmp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lua
        cmp-nvim-lsp
        cmp-nvim-lsp-document-symbol
        cmp-nvim-lsp-signature-help
        cmp-rg
      ])
      ++ (lib.optionals (!isCorpManaged) [upkgs.vimPlugins.copilot-vim])
      ++ (with upkgs; [rustaceanvim]);
  };
}
