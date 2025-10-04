{
  config,
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules) flags;
  inherit ((lib.user.getUserConfig args).modules.system) beans;
in {
  # Packages I always want installed. Most packages I install using per-project
  # flakes sourced with direnv and nix-shell, so this is not a huge list.
  home.packages = with pkgs; [
    coreutils # For consistency across platforms (i.e. GNU utils on macOS).
    devenv # For managing development environments.
    duf # Modern `df` alternative.
    git-get # Used along with fzf and terminal multiplexers for repository management.
    libqalculate # Multi-purpose calculator on the command line.
    nix-output-monitor # Nix Output Monitor.
    tasksh # Task management with taskwarrior.
    tree # List the content of directories in a tree-like format.
    magic-wormhole-rs # Securely transfer files across devices.
    yazi # File explorer that supports Kitty image protocol.

    # Our own package installed by overlay.
    # It's important to keep shadowing the original `pkgs.nvim` package
    # instead of referring to our custom config via another name to maintain
    # all related integrations (e.g. EDITOR) while being able to override it
    # at anytime (e.g. in the corp-specific flavor).
    nvim
  ];

  programs = {
    bash.enable = true;
    bottom.enable = true;
    bat.enable = true; # `cat` replacement.
    fd.enable = true; # `find` replacement.
    ripgrep.enable = true; # `grep` replacement.
    eza.enable = true; # `ls` replacement.
    fzf.enable = true;

    atuin = {
      enable = true;
      enableFishIntegration = true;
      flags = ["--disable-up-arrow"];
      settings = lib.mkIf flags.atuin.enableSync {
        auto_sync = true;
        key_path = args.osConfig.age.secrets."services/atuin.key".path;
        session_path = args.osConfig.age.secrets."services/atuin.session".path;
        sync_frequency = "5m";
        sync_address = flags.atuin.syncAddress;
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        warn_timeout = 0;
        whitelist.prefix =
          [
            "${config.home.homeDirectory}/code"
          ]
          # TODO: make this a flag instead.
          ++ lib.optionals beans.sourceOfTruth ["${config.home.homeDirectory}/beans"];
      };
    };

    keychain = {
      enable = lib.mkDefault true;
      enableFishIntegration = true;
      keys = lib.optionals flags.ssh.installTrustedAccessKeys flags.ssh.trustedAccessKeys;
    };
  };
}
