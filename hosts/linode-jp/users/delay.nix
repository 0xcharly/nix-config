{ flake, ... }:
{
  imports = [
    flake.homeModules.profile-hardware-server
    flake.homeModules.profile-ssh-keys-ring-3-tier
  ];

  home.stateVersion = "25.05";
}
