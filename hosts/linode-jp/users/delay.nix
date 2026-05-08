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
    inputs.nix-config-secrets.homeModules.ssh-keys-ring-3-tier

    flake.homeModules.account-essentials
    flake.homeModules.home-manager-nixos
    flake.homeModules.keychain
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.secrets
    flake.homeModules.ssh-keys
  ];

  home.stateVersion = "25.05";

  node = {
    openssh.trusted-tier.ring = 3;
    services.atuin.enableSync = true;
  };
}
