# Install ring0 SSH identities
{ self, ... }:
{
  flake.nixosModules.install-ssh-identities-ring0 =
    { config, lib, ... }:
    {
      # Install known SSH keys for trusted hosts.
      config.age.secrets =
        let
          keys = self.lib.facts.ssh.delay.trusted-identities;

          mkSshKeyPath = fname: "${config.users.users.delay.home}/.ssh/${fname}";
          mkSshKeyPair = key: {
            "identities/${key}_ed25519_key.pub".path = mkSshKeyPath "${key}.pub";
            "identities/ring0/${key}_ed25519_key".path = mkSshKeyPath key;
          };
        in
        map mkSshKeyPair keys |> lib.mergeAttrsList;
    };
}
