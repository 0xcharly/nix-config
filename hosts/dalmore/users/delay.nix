{ flake, ... }:
{
  imports = [ flake.homeModules.profile-hardware-server ];
  home.stateVersion = "25.05";
}
