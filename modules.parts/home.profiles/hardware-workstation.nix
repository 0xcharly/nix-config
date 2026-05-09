{ self, ... }:
{
  flake.homeModules.profile-hardware-workstation = {
    imports = with self.homeModules; [
      browsers
      desktop-essentials
      devenv
      env
      fonts
      git
      home-manager-nixos
      nixpkgs
      pkgs-desktop-gui
      pkgs-desktop-tui
      programs-atuin
      programs-atuin-sync
      programs-cachix
      programs-coreutils
      programs-fish
      programs-jujutsu
      programs-terminals
      programs-tmux
      secrets
      ssh
      ssh-forgejo
      usb-auto-mount
      wayland-essentials
      wayland-hyprland
      wayland-notifications
      wayland-quickshell
    ];
  };
}
