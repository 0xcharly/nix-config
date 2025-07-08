{
  config,
  lib,
  usrlib,
  ...
}: let
  cfg = config.modules.system.networking;
in
  lib.mkIf (usrlib.bool.isTrue cfg.tailscaleNode) {
    # Create group Tailscale.
    users.groups.tailscale = {};

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
      extraSetFlags = lib.optionals cfg.tailscaleSSH ["--ssh"];
    };
  }
