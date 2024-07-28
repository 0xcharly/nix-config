{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) literalExpression mkOption mkEnableOption types;
  cfg = config.home.nvim-config;
in {
  options.home.nvim-config = {
    enable = mkEnableOption ''
      User-defined configuration for {command}`neovim`.

      Does not compose with `programs.neovim`.
    '';

    src = mkOption {
      type = types.path;
      description = ''
        The neovim lua config root.
      '';
    };

    runtime = mkOption {
      type = with types; listOf path;
      default = [];
      example = literalExpression ''
        [
          ./lib
          ./runtime
        ]
      '';
      description = ''
        List of additional paths to prepend to neovim's RTP.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.neovim-unwrapped;
      defaultText = literalExpression "pkgs.neovim-unwrapped";
      description = "The package to use for the neovim binary.";
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = "Resulting customized neovim package.";
    };

    patches = mkOption {
      type = with types; listOf path;
      default = [];
      example = literalExpression ''
        [
          0001-hotfix.patch
          0002-feature.patch
        ]
      '';
      description = ''
        List of patches to apply to the package.
      '';
    };

    plugins = mkOption {
      type = with types; listOf package;
      default = [];
      example = literalExpression ''
        with pkgs.vimPlugins; [
          yankring
          vim-nix
        ]
      '';
      description = ''
        List of vim plugins to install.
      '';
    };
  };

  config = lib.mkIf cfg.enable (let
    mkNeovimPackage = import ./mk-nvim-config.nix pkgs;
  in {
    home.nvim-config.finalPackage = mkNeovimPackage {
      inherit (cfg) src runtime package patches plugins;
    };
    home.packages = [cfg.finalPackage];

    # NOTE: This module is evaluated in the context of home-manager's modules, in
    # which `config.flake` does not exist.
    # TODO: Is it possible to surface the package in outputs.packages.<platforms>?
    # flake.packages.nvim = cfg.finalPackage;
  });
}
