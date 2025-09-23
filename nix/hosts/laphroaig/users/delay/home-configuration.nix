{
  flake,
  inputs,
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
    flake.modules.home.keychain
    flake.modules.home.pkgs-desktop-gui
    flake.modules.home.pkgs-desktop-tui
    flake.modules.home.pkgs-laptop-tui
    flake.modules.home.secrets
    flake.modules.home.ssh-keys
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
      hyprland.monitor = "";
      waybar.output = ["DP-1"];
    };
  };
}
