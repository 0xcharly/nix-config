{
  config,
  lib,
  ...
}: {
  options.node.openssh.trusted-tier = with lib; {
    ring = mkOption {
      type = types.enum [0 3];
      default = 3;
      description = ''
        The trust access tier of the machine.
        3 for least trusted and 0 for highly trusted.
      '';
    };
  };

  # Install known SSH keys for trusted hosts.
  config.home.file = let
    cfg = config.node.openssh.trusted-tier;
    keys = ["github" "git_commit_signing" "tailscale"];

    mkOutOfStoreSymlink = tier: fname: config.lib.file.mkOutOfStoreSymlink config.age.secrets."keys/${tier}-access/${fname}".path;
    mkSshKeySymLink = tier: key: {
      ".ssh/${key}".source = mkOutOfStoreSymlink tier "${key}_ed25519_key";
      ".ssh/${key}.pub".source = mkOutOfStoreSymlink tier "${key}_ed25519_key.pub";
    };

    mkSshKeyList = {
      ring,
      tier,
    }:
      lib.optionals (cfg.ring == ring) (builtins.map (mkSshKeySymLink tier) keys);
  in
    lib.mergeAttrsList (lib.flatten (builtins.map mkSshKeyList [
      {
        ring = 3;
        tier = "basic";
      }
      {
        ring = 0;
        tier = "trusted";
      }
    ]));
}
