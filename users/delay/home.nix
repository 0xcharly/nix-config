{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  inherit (pkgs.stdenv) isLinux;
  inherit (config.modules.usrenv) isLinuxDesktop;
in {
  imports = [
    ./browsers.nix
    ./catppuccin.nix
    ./fonts.nix
    ./hyprland.nix
    ./linux-desktop.nix
    ./multiplexers.nix
    ./nix-client-config.nix
    ./nixos.nix
    ./raycast.nix
    ./scripts.nix
    ./shells.nix
    ./ssh.nix
    ./systemd-timers.nix
    ./terminals.nix
    ./vcs.nix
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
    ++ lib.optionals isLinux [pkgs.valgrind]
    ++ lib.optionals isLinuxDesktop [pkgs.nvtopPackages.full];

  home.sessionVariables = rec {
    LANG = "en_US.UTF-8";
    LC_CTYPE = LANG;
    LC_ALL = LANG;
    EDITOR = lib.getExe pkgs.nvim;
    VISUAL = EDITOR;
    MANPAGER = "${lib.getExe pkgs.nvim} +Man!";
    PAGER = "less -FirSwX";
  };
}
