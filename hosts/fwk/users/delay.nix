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
    flake.homeModules.opencode
    flake.homeModules.pkgs-desktop-gui
    flake.homeModules.pkgs-desktop-tui
    flake.homeModules.pkgs-laptop-tui
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
      hyprland.monitor = "eDP-1, 2880x1920@120.00000, 0x0, 1.50";

      display.logicalResolution = {
        width = 1920;
        height = 1280;
      };

      pip = {
        width = 640;
        height = 360;
      };

      idle = {
        suspend.timeout = 15 * 60; # 15 minutes.
        hibernate = {
          enable = true;
          timeout = 30 * 60; # 30 minutes.
        };
        screenlock.fingerprint.enable = true;
      };

      uwsm-wrapper = {
        package = perSystem.self.app2unit;
        prefix = "${lib.getExe config.node.wayland.uwsm-wrapper.package} --";
      };

      arcshell.modules.power = true;
    };
  };
}
