{
  flake,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin

    flake.modules.home.account-essentials
    flake.modules.home.home-manager-nixos
    flake.modules.home.secrets
  ];

  home.stateVersion = "25.05";

  node.services.atuin.enableSync = true;
}
