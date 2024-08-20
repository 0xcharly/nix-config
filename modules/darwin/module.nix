{pkgs, ...}: {
  imports = [
    ./aarch64-darwin.nix
    ./homebrew.nix
    ./macos.nix
    ./nix-client-config.nix
    ./nix-homebrew.nix
    ./nix-index.nix
    ./unfree.nix
  ];

  modules.usrenv.compositor = "quartz";

  # Mark admins as trusted users to enable cachix repositories.
  nix.settings.trusted-users = ["@admin"];

  # We install Nix using a separate installer so we don't want nix-darwin
  # to manage it for us. This tells nix-darwin to just use whatever is running.
  nix.useDaemon = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # zsh is the default shell on Mac and we want to make sure that we're
  # configuring the rc correctly with nix-darwin paths.
  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix
  '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix
  '';

  environment.shells = with pkgs; [bashInteractive zsh fish];

  # The user should already exist, but we need to set this up so Nix knows
  # what our home directory is (https://github.com/LnL7/nix-darwin/issues/423).
  users.users.delay = {
    home = "/Users/delay";
    shell = pkgs.zsh;
  };
}
