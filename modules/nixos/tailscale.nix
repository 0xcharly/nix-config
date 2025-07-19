{
  config,
  lib,
  ...
}: let
  cfg = config.modules.system.networking;
in
  lib.mkIf (lib.fn.isTrue cfg.tailscaleNode) {
    # Create group Tailscale.
    users.groups.tailscale = {};

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
      extraSetFlags = lib.optionals cfg.tailscaleSSH ["--ssh"];
    };
  }
