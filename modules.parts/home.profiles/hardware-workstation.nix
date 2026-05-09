{ self, ... }:
{
  flake.homeModules.profile-hardware-workstation = {
    imports = with self.homeModules; [
      environment
      environment-desktop
      environment-desktop-wayland
      environment-development
      home-manager-nixos
      install-fonts
      nixpkgs
      pkgs-desktop-gui
      pkgs-desktop-tui
      programs-atuin
      programs-atuin-sync
      programs-browsers
      programs-cachix
      programs-coreutils
      programs-fish
      programs-opencode
      programs-ssh
      programs-terminals
      programs-tmux
      programs-vcs
      secrets
      services-usb-auto-mount
    ];
  };
}
