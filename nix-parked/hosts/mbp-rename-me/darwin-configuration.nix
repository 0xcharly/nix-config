{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.modules.common.nix-client-config
    flake.modules.common.nix-path
    flake.modules.common.nixpkgs-unfree
    flake.modules.common.nixpkgs-unstable
    flake.modules.common.overlays

    flake.modules.darwin.homebrew
    flake.modules.darwin.nix-client-config
    flake.modules.darwin.nixpkgs-flake
    flake.modules.darwin.shells
    flake.modules.darwin.system-defaults

    flake.modules.home.atuin
    flake.modules.home.catppuccin
    flake.modules.home.fish
    flake.modules.home.fonts
    flake.modules.home.ghostty
    flake.modules.home.git
    flake.modules.home.jujutsu
    flake.modules.home.jujutsu-deprecated
    flake.modules.home.keychain
    flake.modules.home.keychain-trusted-keys
    flake.modules.home.pkgs-essentials
    flake.modules.home.tmux

    ./homebrew.nix
  ];

  ids.gids.nixbld = 30000;

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    primaryUser = "delay";

    # Akin to Home Manager's `stateVersion`, and NixOS' `system.stateVersion`, but
    # it independent from releases (e.g. "24.11").
    # This value determines the nix-darwin release from which the default settings
    # for stateful data, like file locations and database versions on your system
    # were taken. It‘s perfectly fine and recommended to leave this value at the
    # release version of the first install of this system. Before changing this
    # value read the documentation for this option.
    # https://mynixos.com/nix-darwin/option/system.stateVersion
    stateVersion = 5; # Did you read the comment?
  };

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.fish;
  };
}
