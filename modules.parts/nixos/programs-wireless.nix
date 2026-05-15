{
  flake.nixosModules.programs-wireless = {
    networking.networkmanager.enable = true;
    users.users.delay.extraGroups = [ "networkmanager" ];
  };
}
