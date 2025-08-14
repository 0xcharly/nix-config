{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.immich;
in {
  options.node.services.immich.enable = lib.mkEnableOption "Whether to spin up an Immich server.";

  config.services.immich = {
    inherit (cfg) enable;
    host = "0.0.0.0";
    mediaLocation = "/tank/delay/album";
    settings.server.externalDomain = "https://shared.album.qyrnl.com";
  };
}
