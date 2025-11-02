{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.immich = with lib; {
    enable = mkEnableOption "Spin up an Immich service";
  };

  config = let
    cfg = config.node.services.immich;
    inherit (flake.lib) caddy facts gatus;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      redis-immich = {
        owner = config.services.redis.servers.immich.user;
        group = config.services.redis.servers.immich.group;
        mode = "0700";
      };
    };

    services = {
      immich = {
        inherit (cfg) enable;
        host = "0.0.0.0";
        inherit (facts.services.immich) port;
        mediaLocation = "/tank/delay/album";
        settings.server.externalDomain = "https://${facts.services.immich-public-proxy.domain}";
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.immich;
      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "immich" facts.services.immich)
      ];
    };
  };
}
