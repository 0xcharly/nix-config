{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.nix-config-secrets.nixosModules.agenix
    inputs.nix-config-secrets.nixosModules.sops
  ];

  age.secrets."services/cachix.dhall" = {
    path = "${config.users.users.delay.home}/.config/cachix/cachix.dhall";
  };
}
