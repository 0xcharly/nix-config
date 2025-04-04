{
  config,
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isLinux;

  isGenericLinux = pkgs.stdenv.isLinux && (config.targets.genericLinux.enable or false);
  isNixOS = pkgs.stdenv.isLinux && !(config.targets.genericLinux.enable or false);
in {
  imports = [
    inputs.catppuccin.homeManagerModules.catppuccin

    ./browsers.nix
    ./catppuccin.nix
    ./fonts.nix
    ./hyprland.nix
    ./multiplexers.nix
    ./nix-client-config.nix
    ./nixos-desktop.nix
    ./scripts.nix
    ./shells.nix
    ./ssh.nix
    ./terminals.nix
    ./vcs.nix
    ./x11.nix
  ];

  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
  home.packages = with pkgs;
    [
      coreutils # For consistency across platforms (i.e. GNU utils on macOS).
      devenv # For managing development environments.
      duf # Modern `df` alternative.
      git-get # Used along with fzf and terminal multiplexers for repository management.
      libqalculate # Multi-purpose calculator on the command line.
      tree # List the content of directories in a tree-like format.
      yazi # File explorer that supports Kitty image protocol.

      # Our own package installed by overlay.
      # It's important to keep shadowing the original `pkgs.nvim` package
      # instead of referring to our custom config via another name to maintain
      # all related integrations (e.g. EDITOR) while being able to override it
      # at anytime (e.g. in the corp-specific flavor).
      nvim
    ]
    ++ lib.optionals isLinux [pkgs.valgrind];

  home.sessionVariables = rec {
    LANG = "en_US.UTF-8";
    LC_CTYPE = LANG;
    LC_ALL = LANG;
    EDITOR = lib.getExe pkgs.nvim;
    VISUAL = EDITOR;
    MANPAGER = "${lib.getExe pkgs.nvim} +Man!";
    PAGER = "less -FirSwX";
  };

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin.flavor = "mocha";

  xdg.configFile = lib.optionalAttrs isNixOS {
    "cachix/cachix.dhall".source = config.lib.file.mkOutOfStoreSymlink osConfig.age.secrets."services/cachix.dhall".path;
  };
}
