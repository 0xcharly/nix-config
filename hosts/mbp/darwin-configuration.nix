{ flake, pkgs, ... }:
{
  imports = [
    flake.darwinModules.homebrew
    flake.darwinModules.nix
    flake.darwinModules.nixpkgs
    flake.darwinModules.system-defaults
    flake.darwinModules.system-shells
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
