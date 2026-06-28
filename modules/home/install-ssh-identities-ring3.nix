# Install ring3 SSH identities
{ self, ... }:
{
  flake.homeModules.install-ssh-identities-ring3 =
    { config, lib, ... }:
    {
      config.age.secrets =
        let
          keys = self.lib.facts.ssh.delay.trusted-identities;

          mkSshKeyPath = fname: "${config.home.homeDirectory}/.ssh/${fname}";
          mkSshKeyPair = key: {
            "identities/${key}_ed25519_key.pub".path = mkSshKeyPath "${key}.pub";
            "identities/ring3/${key}_ed25519_key".path = mkSshKeyPath key;
          };
        in
        map mkSshKeyPair keys |> lib.mergeAttrsList;
    };
}
