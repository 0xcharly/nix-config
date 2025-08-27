{
  networking.networkmanager.enable = true;
  users.users.delay.extraGroups = ["networkmanager"];
}
