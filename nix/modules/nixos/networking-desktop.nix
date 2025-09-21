{flake, ...}: {
  imports = [flake.modules.nixos.networking-common];

  # NetworkManager is controlled using either nmcli or nmtui.
  networking.networkmanager.enable = true;

  # All users that should have permission to change network settings must belong
  # to the networkmanager group:
  users.users.delay.extraGroups = ["networkmanager"];
}
