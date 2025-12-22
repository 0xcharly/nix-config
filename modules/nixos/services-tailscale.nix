{
  config,
  lib,
  ...
}: let
  cfg = config.node.networking.tailscale;
in {
  options.node.networking.tailscale = with lib; {
    enableSsh = mkEnableOption "Whether to enable Tailscale SSH";
    acceptRoutes = mkEnableOption "Whether to accept routes advertised by other peers";
  };

  config = {
    # Create group Tailscale.
    users.groups.tailscale = {};

    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets."services/tailscale-preauth.key".path;
      extraSetFlags = let
        mkFlags = flags: flags |> lib.mapAttrsToList (flag: enable: lib.optional enable flag) |> lib.concatLists;
      in
        mkFlags {
          "--ssh" = cfg.enableSsh;
          "--accept-routes" = cfg.acceptRoutes;
        };
    };
  };
}
