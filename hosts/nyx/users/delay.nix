{ flake, inputs, ... }:
{
  imports = [
    inputs.nix-config-secrets.homeModules.services-atuin
    inputs.nix-config-secrets.homeModules.ssh-keys-ring-0-tier

    flake.homeModules.account-essentials
    flake.homeModules.browsers
    flake.homeModules.cachix
    flake.homeModules.desktop-essentials
    flake.homeModules.fonts
    flake.homeModules.home-manager-nixos
    flake.homeModules.keychain
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.opencode
    flake.homeModules.pkgs-desktop-gui
    flake.homeModules.pkgs-desktop-tui
    flake.homeModules.secrets
    flake.homeModules.ssh-forgejo
    flake.homeModules.ssh-keys
    flake.homeModules.terminals
    flake.homeModules.usb-auto-mount
    flake.homeModules.wayland-essentials
    flake.homeModules.wayland-hyprland
    flake.homeModules.wayland-notifications
    flake.homeModules.wayland-quickshell
  ];

  home.stateVersion = "25.05";

  node = {
    openssh.trusted-tier.ring = 0;
    services.atuin.enableSync = true;
    wayland = {
      hyprland.monitor = "DP-3, 6016x3384@60.00Hz, 0x0, 2.00";

      display.logicalResolution = {
        width = 3008;
        height = 1692;
      };

      arcshell.wallpaper.animate = true;
    };
  };
}
