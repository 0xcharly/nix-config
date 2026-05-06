{
  # Blueprint parameters.
  flake,
  inputs,
  perSystem,
  # Module parameters.
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.nix-config-secrets.homeModules.default
    inputs.nix-config-secrets.homeModules.services-atuin
    inputs.nix-config-secrets.homeModules.services-cachix
    inputs.nix-config-secrets.homeModules.ssh-keys-ring-0-tier

    flake.modules.common.nixpkgs-unstable

    flake.homeModules.account-essentials
    flake.homeModules.browsers
    flake.homeModules.cachix
    flake.homeModules.desktop-essentials
    flake.homeModules.fonts
    flake.homeModules.home-manager-nixos
    flake.homeModules.keychain
    flake.homeModules.pkgs-desktop-gui
    flake.homeModules.pkgs-desktop-tui
    flake.homeModules.secrets
    flake.homeModules.ssh-forgejo
    flake.homeModules.ssh-keys
    flake.homeModules.terminals
    flake.homeModules.usb-auto-mount
    flake.homeModules.walker
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
      hyprland.monitor = "DP-1, 3840x2160@59.997Hz, 0x0, 1.25";

      display.logicalResolution = {
        width = 3072;
        height = 1728;
      };

      idle = {
        screenlock.enable = true;
        suspend.enable = false;
      };
    };
  };
}
