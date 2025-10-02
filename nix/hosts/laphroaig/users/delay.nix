{
  # Blueprint parameters.
  flake,
  inputs,
  perSystem,
  # Module parameters.
  lib,
  config,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin
    inputs.nix-config-secrets.modules.home.services-cachix
    inputs.nix-config-secrets.modules.home.services-taskwarrior
    inputs.nix-config-secrets.modules.home.ssh-keys-ring-0-tier

    flake.modules.home.account-essentials
    flake.modules.home.browsers
    flake.modules.home.cachix
    flake.modules.home.desktop-essentials
    flake.modules.home.fonts
    flake.modules.home.ghostty
    flake.modules.home.home-manager-nixos
    flake.modules.home.jujutsu-deprecated
    flake.modules.home.keychain
    flake.modules.home.pkgs-desktop-gui
    flake.modules.home.pkgs-desktop-tui
    flake.modules.home.pkgs-laptop-tui
    flake.modules.home.secrets
    flake.modules.home.ssh-keys
    flake.modules.home.usb-auto-mount
    flake.modules.home.walker
    flake.modules.home.wayland-essentials
    flake.modules.home.wayland-hyprland
    flake.modules.home.wayland-notifications
    flake.modules.home.wayland-waybar
  ];

  home.stateVersion = "25.05";

  node = {
    openssh.trusted-tier.ring = 0;
    services = {
      atuin.enableSync = true;
      tasks.enableSync = true;
    };
    wayland = {
      hyprland.monitor = "eDP-1, 2880x1920@120.00000, 0x0, 2.00";

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

      waybar = {
        output = ["eDP-1"];
        extra-modules-right = ["battery"];
      };
    };
  };
}
