{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.keychain = with lib; {
    autoLoadTrustedKeys = mkOption {
      type = types.bool;
      default = config.node.openssh.trusted-tier.ring == 0;

      description = ''
        Loads trusted keys on startup.

        NOTE: Requires trusted keys to be installed under ~/.ssh.
        This is only recommended on machines where ring-0 keys are installed.
      '';
    };
  };

  config.programs.keychain = let
    cfg = config.node.keychain;
  in {
    enable = true;
    enableFishIntegration = true;

    # Clears ["id_rsa"] default either way.
    keys = lib.optionals cfg.autoLoadTrustedKeys flake.lib.facts.ssh.delay.trusted-keys;
  };
}
