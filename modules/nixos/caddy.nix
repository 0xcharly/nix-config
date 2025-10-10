{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.reverseProxy;
in {
  options.node.services.reverseProxy.enable = lib.mkEnableOption ''
    Whether to serve services from across the internal network
    behind a reverse proxy.
  '';

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/gandi@v1.1.0"];
        hash = "sha256-VxJlx1X4nrqprgcPRFt/pMc5Ix8YV61ou8dwLcR6v2U=";
      };
      environmentFile = config.age.secrets."services/gandi-creds.qyrnl.com".path;
      virtualHosts."(ts_host)".extraConfig = ''
        tls {
          resolvers 1.1.1.1
          dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
        }
      '';
    };

    # Allow Caddy to bind to 443.
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
      EnvironmentFile = config.age.secrets."services/gandi-creds.qyrnl.com".path;
    };
  };
}
