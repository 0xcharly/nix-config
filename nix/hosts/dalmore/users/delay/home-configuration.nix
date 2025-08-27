{
  flake,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.modules.home.blueprint
    inputs.nix-config-secrets.modules.home.services-atuin
    inputs.nix-config-secrets.modules.home.services-taskwarrior

    flake.modules.home.home-manager-nixos
    flake.modules.home.secrets
    flake.modules.home.users-delay
  ];

  home.stateVersion = "25.05";

  node.services = {
    atuin.enableSync = true;
    tasks.enableSync = true;
  };
}
