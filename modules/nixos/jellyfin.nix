{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.jellyfin;
in {
  options.node.services.jellyfin.enable = lib.mkEnableOption "Whether to spin up a Jellyfin server.";

  config.services.jellyfin = {
    inherit (cfg) enable;
  };
}
