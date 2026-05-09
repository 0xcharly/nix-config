{ self, inputs, ... }:
{
  flake.homeModules.profile-ssh-keys-ring-3-tier = {
    imports = [
      inputs.nix-config-secrets.homeModules.ssh-keys-ring-3-tier

      self.homeModules.install-ssh-keys
      self.homeModules.programs-keychain
    ];

    node.openssh.trusted-tier.ring = 3;
  };
}
