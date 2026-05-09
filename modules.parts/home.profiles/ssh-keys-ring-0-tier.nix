{ self, inputs, ... }:
{
  flake.homeModules.profile-ssh-keys-ring-0-tier = {
    imports = [
      inputs.nix-config-secrets.homeModules.ssh-keys-ring-0-tier

      self.homeModules.keychain
      self.homeModules.ssh-keys
    ];

    node.openssh.trusted-tier.ring = 0;
  };
}
