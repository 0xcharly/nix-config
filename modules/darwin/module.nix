{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ./aarch64-darwin.nix
    ./homebrew.nix
    ./macos.nix
    ./nix-client-config.nix
    ./nix-homebrew.nix
    ./user-delay.nix
  ];

  modules.usrenv.compositor = "quartz";

  # Akin to Home Manager's `stateVersion`, and NixOS' `system.stateVersion`, but
  # it independent from releases (e.g. "24.11").
  # This value determines the nix-darwin release from which the default settings
  # for stateful data, like file locations and database versions on your system
  # were taken. It‘s perfectly fine and recommended to leave this value at the
  # release version of the first install of this system. Before changing this
  # value read the documentation for this option.
  # https://mynixos.com/nix-darwin/option/system.stateVersion
  system.stateVersion = lib.mkDefault 5; # Did you read the comment?

  # TODO: documentation.
  system.primaryUser = config.modules.system.mainUser;

  # Fish is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
  '';

  environment.shells = with pkgs; [bashInteractive zsh fish];
}
