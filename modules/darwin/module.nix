{pkgs, lib, ...}: {
  imports = [
    ./aarch64-darwin.nix
    ./default-shell.nix
    ./homebrew.nix
    ./macos.nix
    ./nix-client-config.nix
    ./nix-homebrew.nix
    ./nix-index.nix
    ./unfree.nix
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

  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  nix.useDaemon = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

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

  environment.shells = with pkgs; [bashInteractive fish];

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.fish;
  };
}
