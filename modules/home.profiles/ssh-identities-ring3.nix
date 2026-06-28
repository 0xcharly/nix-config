{ self, inputs, ... }:
{
  flake.homeModules.profile-ssh-identities-ring3.imports = [
    inputs.nix-config-secrets.homeModules.identities-ssh-pub
    inputs.nix-config-secrets.homeModules.identities-ssh-ring3

    self.homeModules.install-ssh-identities-ring3
  ];
}
