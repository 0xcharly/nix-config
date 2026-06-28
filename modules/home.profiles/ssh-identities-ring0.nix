{ self, inputs, ... }:
{
  flake.nixosModules.profile-ssh-identities-ring0.imports = [
    inputs.nix-config-secrets.nixosModules.identities-ssh-pub
    inputs.nix-config-secrets.nixosModules.identities-ssh-ring0

    self.nixosModules.install-ssh-identities-ring0
  ];

  flake.homeModules.profile-ssh-identities-ring0.node.keychain.autoLoadTrustedIdentities = true;
}
