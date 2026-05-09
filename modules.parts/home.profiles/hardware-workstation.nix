{ self, ... }:
{
  flake.homeModules.profile-hardware-workstation = {
    imports = with self.homeModules; [
      account-essentials
      browsers
      desktop-essentials
      fonts
      home-manager-nixos
      nixpkgs
      pkgs-desktop-gui
      pkgs-desktop-tui
      programs-atuin-sync
      programs-cachix
      secrets
      ssh-forgejo
      terminals
      usb-auto-mount
      wayland-essentials
      wayland-hyprland
      wayland-notifications
      wayland-quickshell
    ];
  };
}
