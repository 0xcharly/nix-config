{ self, ... }:
{
  flake.homeModules.profile-hardware-workstation = {
    imports = with self.homeModules; [
      account-essentials
      atuin-sync
      browsers
      cachix
      desktop-essentials
      fonts
      home-manager-nixos
      nixpkgs
      pkgs-desktop-gui
      pkgs-desktop-tui
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
