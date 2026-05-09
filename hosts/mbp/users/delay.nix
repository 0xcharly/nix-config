{ flake, ... }:
{
  imports = [
    flake.homeModules.account-essentials
    flake.homeModules.fonts
    flake.homeModules.home-manager-nixos
    flake.homeModules.keychain
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.terminals
  ];

  home.stateVersion = "24.05";

  node.keychain.autoLoadTrustedKeys = false;
}
