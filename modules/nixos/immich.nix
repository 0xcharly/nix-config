{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.immich;
in {
  options.node.services.immich.enable = lib.mkEnableOption "Whether to spin up an Immich server.";

  config.services = {
    immich = {
      inherit (cfg) enable;
      host = "0.0.0.0";
      mediaLocation = "/tank/delay/album";
      settings.server.externalDomain = "https://shared.album.qyrnl.com";
    };

    # TODO: define Immich's host somewhere else.
    caddy.virtualHosts."album.qyrnl.com" = {
      extraConfig = ''
        import ts_host
        reverse_proxy helios.qyrnl.com:${toString config.services.immich.port}
      '';
    };
  };
}
