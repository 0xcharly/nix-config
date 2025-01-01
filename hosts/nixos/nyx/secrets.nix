{inputs, ...}: {
  imports = [
    inputs.nix-config-secrets.nixosModules.agenix
    inputs.nix-config-secrets.nixosModules.sops
  ];
}
