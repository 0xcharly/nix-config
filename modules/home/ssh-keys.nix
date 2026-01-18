{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  options.node.openssh.trusted-tier = with lib; {
    ring = mkOption {
      type = types.enum [
        0
        3
      ];
      default = 3;
      description = ''
        The trust access tier of the machine.
        3 for least trusted and 0 for highly trusted.
      '';
    };
  };

  # Install known SSH keys for trusted hosts.
  config.age.secrets =
    let
      cfg = config.node.openssh.trusted-tier;
      tier = if (cfg.ring == 0) then "trusted" else "basic";
      keys = flake.lib.facts.ssh.delay.trusted-keys;

      mkSshKeyPath = fname: "${config.home.homeDirectory}/.ssh/${fname}";
      mkSshKeyPair = tier: key: {
        "keys/${tier}-access/${key}_ed25519_key".path = mkSshKeyPath key;
        "keys/${tier}-access/${key}_ed25519_key.pub".path = mkSshKeyPath "${key}.pub";
      };
    in
    lib.mergeAttrsList (builtins.map (mkSshKeyPair tier) keys);
}
