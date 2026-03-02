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
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin
    inputs.nix-config-secrets.modules.home.services-cachix
    inputs.nix-config-secrets.modules.home.ssh-keys-ring-0-tier

    flake.modules.home.account-essentials
    flake.modules.home.browsers
    flake.modules.home.cachix
    flake.modules.home.desktop-essentials
    flake.modules.home.fonts
    flake.modules.home.ghostty
    flake.modules.home.home-manager-nixos
    flake.modules.home.keychain
    flake.modules.home.kitty
    flake.modules.home.pkgs-desktop-gui
    flake.modules.home.pkgs-desktop-tui
    flake.modules.home.secrets
    flake.modules.home.ssh-forgejo
    flake.modules.home.ssh-keys
    flake.modules.home.usb-auto-mount
    flake.modules.home.walker
    flake.modules.home.wayland-essentials
    flake.modules.home.wayland-hyprland
    flake.modules.home.wayland-notifications
    flake.modules.home.wayland-quickshell
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

      uwsm-wrapper = {
        package = perSystem.self.app2unit;
        prefix = "${lib.getExe config.node.wayland.uwsm-wrapper.package} --";
      };
    };
  };
}
