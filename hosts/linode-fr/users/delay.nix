{
  # Blueprint parameters.
  flake,
  inputs,
  # Module parameters.
  ...
}:
{
  imports = [
    inputs.nix-config-secrets.homeModules.default
    inputs.nix-config-secrets.homeModules.services-atuin

    flake.modules.common.nixpkgs-unstable

    flake.homeModules.account-essentials
    flake.homeModules.home-manager-nixos
    flake.homeModules.secrets
  ];

  home.stateVersion = "25.05";

  node.services.atuin.enableSync = true;
}
