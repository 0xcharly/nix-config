{ self, inputs, ... }:
{
  flake.homeModules.profile-ssh-keys-ring-0-tier = {
    imports = [
      inputs.nix-config-secrets.homeModules.identities-ssh-pub
      inputs.nix-config-secrets.homeModules.identities-ssh-ring3
      inputs.nix-config-secrets.homeModules.ssh-keys-ring-0-tier

      self.homeModules.install-ssh-keys
    ];

    node.openssh.trusted-tier.ring = 0;
  };
}
