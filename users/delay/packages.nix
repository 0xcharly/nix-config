{
  config,
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit (pkgs.stdenv) isLinux;
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) isLinuxDesktop;
in {
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

  programs = {
    bash.enable = true;
    bottom.enable = true;
    bat.enable = true; # `cat` replacement.
    fd.enable = true; # `find` replacement.
    ripgrep.enable = true; # `grep` replacement.
    eza.enable = true; # `ls` replacement.
    fzf.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.whitelist.prefix = [
        "${config.home.homeDirectory}/code"
      ];
    };

    keychain = {
      enable = lib.mkDefault true;
      keys = []; # TODO: Add keys.
    };
  };
}
