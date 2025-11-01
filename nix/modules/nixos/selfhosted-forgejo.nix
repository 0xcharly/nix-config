{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.forgejo = with lib; {
    enable = mkEnableOption "Spin up a Forgejo service";
  };

  config = let
    cfg = config.node.services.forgejo;
    inherit (flake.lib) caddy facts gatus;
  in {
    node = lib.mkIf cfg.enable {
      fs.zfs.zpool.root.datadirs.forgejo = {};
    };

    services = {
      forgejo = {
        inherit (cfg) enable;
        stateDir = config.node.fs.zfs.zpool.root.datadirs.forgejo.absolutePath;
        repositoryRoot = "/tank/delay/forge/repo";
        lfs = {
          enable = true;
          contentDir = "/tank/delay/forge/data";
        };
        settings = {
          cache = {
            ADAPTER = "redis";
            HOST = "redis+socket://${config.services.redis.servers.forgejo.unixSocket}";
          };
          server = {
            DISABLE_SSH = true;
            DOMAIN = facts.services.forgejo.domain;
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = facts.services.forgejo.port;
          };
          session.COOKIE_SECURE = true;
        };

        redis.servers.forgejo = {
          inherit (cfg) enable;
          port = 0; # Disables TCP.
        };
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.forgejo;
      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "forgejo" facts.services.forgejo)
      ];
    };
  };
}
