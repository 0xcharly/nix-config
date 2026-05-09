{ flake, ... }:
{
  imports = [
    flake.homeModules.account-essentials
    flake.homeModules.atuin-sync
    flake.homeModules.home-manager-nixos
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.secrets
  ];

  home.stateVersion = "25.11";
}
