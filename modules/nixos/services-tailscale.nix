{
  config,
  lib,
  ...
}: let
  cfg = config.node.networking.tailscale;
in {
  options.node.networking.tailscale = with lib; {
    enableSsh = mkEnableOption "Whether to enable Tailscale SSH";
  };

  config = {
    # Create group Tailscale.
    users.groups.tailscale = {};

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
      extraSetFlags = lib.optionals cfg.enableSsh ["--ssh"];
    };
  };
}
