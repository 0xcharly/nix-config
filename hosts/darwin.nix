{pkgs, ...}: {
  imports = [
    ./hw/aarch64-darwin.nix
    ./os/macos.nix
    ./shared/macos.nix
  ];

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

  environment.shells = with pkgs; [bashInteractive zsh fish];

  fonts = {
    fontDir.enable = true;
    # nix-darwin still uses `fonts.fonts` instead of the new `fonts.packages`.
    # https://github.com/LnL7/nix-darwin/pull/754
    fonts = import ../modules/fonts {pkgs = pkgs;};
  };
}
