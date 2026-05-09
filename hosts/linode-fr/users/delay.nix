{ flake, inputs, ... }:
{
  imports = [
    inputs.nix-config-secrets.homeModules.services-atuin

    flake.homeModules.account-essentials
    flake.homeModules.home-manager-nixos
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.secrets
  ];

  home.stateVersion = "25.05";

  node.services.atuin.enableSync = true;
}
