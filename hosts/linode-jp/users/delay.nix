{ flake, inputs, ... }:
{
  imports = [
    inputs.nix-config-secrets.homeModules.ssh-keys-ring-3-tier

    flake.homeModules.account-essentials
    flake.homeModules.atuin-sync
    flake.homeModules.home-manager-nixos
    flake.homeModules.keychain
    flake.homeModules.nixpkgs-unstable
    flake.homeModules.secrets
    flake.homeModules.ssh-keys
  ];

  home.stateVersion = "25.05";

  node.openssh.trusted-tier.ring = 3;
}
