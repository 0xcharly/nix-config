{ self, ... }:
{
  flake.homeModules.profile-hardware-workstation = {
    imports = with self.homeModules; [
      environment
      environment-desktop
      environment-desktop-wayland
      environment-development
      fonts
      home-manager-nixos
      nixpkgs
      pkgs-desktop-gui
      pkgs-desktop-tui
      programs-atuin
      programs-atuin-sync
      programs-browsers
      programs-cachix
      programs-coreutils
      programs-fish
      programs-terminals
      programs-tmux
      programs-vcs
      secrets
      ssh
      ssh-forgejo
      usb-auto-mount
    ];
  };
}
