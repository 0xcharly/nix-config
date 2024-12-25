{
  inputs,
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) isHeadless;
  inherit (pkgs.stdenv) isLinux;

  hasWindowManager = !isHeadless;
in {
  imports = [
    inputs.catppuccin.homeManagerModules.catppuccin

    ./browsers.nix
    ./desktop.nix
    ./fonts.nix
    ./multiplexers.nix
    ./nix-client-config.nix
    ./scripts.nix
    ./shells.nix
    ./ssh.nix
    ./terminals.nix
    ./vcs.nix
    ./wayland.nix
    ./x11.nix
  ];

  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
  home.packages =
    [
      pkgs.coreutils # For consistency across platforms (i.e. GNU utils on macOS).
      pkgs.duf # Modern `df` alternative.
      pkgs.git-get # Used along with fzf and terminal multiplexers for repository management.
      pkgs.libqalculate # Multi-purpose calculator on the command line.
      pkgs.tree # List the content of directories in a tree-like format.
      pkgs.yazi # File explorer that supports Kitty image protocol.

      # Our own package installed by overlay.
      # It's important to keep shadowing the original `pkgs.nvim` package
      # instead of referring to our custom config via another name to maintain
      # all related integrations (e.g. EDITOR) while being able to override it
      # at anytime (e.g. in the corp-specific flavor).
      pkgs.nvim
    ]
    ++ lib.optionals hasWindowManager [pkgs.ghostty]
    ++ lib.optionals isLinux [pkgs.valgrind];

  home.sessionVariables = rec {
    LANG = "en_US.UTF-8";
    LC_CTYPE = LANG;
    LC_ALL = LANG;
    EDITOR = lib.getExe pkgs.nvim;
    MANPAGER = "${EDITOR} +Man!";
    PAGER = "less -FirSwX";
  };

  # Configure catppuccin theme applied throughout the configuration.
  catppuccin.flavor = "mocha";
}
