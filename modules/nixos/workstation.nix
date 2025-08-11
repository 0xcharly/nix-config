{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.workstation {
  # Configure nixpkgs.
  nixpkgs.config.allowUnfree = true;

  # Automount removable devices (used by udiskie).
  services.udisks2.enable = true;

  # Networking.
  # NetworkManager is controlled using either nmcli or nmtui.
  networking.networkmanager.enable = true;
  # All users that should have permission to change network settings must belong
  # to the networkmanager group:
  users.users.delay.extraGroups = ["networkmanager"];
}
