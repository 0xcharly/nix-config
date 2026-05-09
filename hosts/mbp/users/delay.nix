{ flake, ... }:
{
  imports = [ flake.homeModules.profile-hardware-macbook ];
  home.stateVersion = "24.05";
}
