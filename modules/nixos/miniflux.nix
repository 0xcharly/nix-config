{
  lib,
  config,
  ...
}: let
  cfg = config.node.services.miniflux;
in {
  options.node.services.miniflux.enable = lib.mkEnableOption "Whether to spin up a Miniflux 2 server.";

  config = {
    services = {
      miniflux = {
        inherit (cfg) enable;
        adminCredentialsFile = config.age.secrets."services/miniflux-admin-creds".path;
        config = {
          BASE_URL = "https://news.qyrnl.com";
          CREATE_ADMIN = 1;
          PORT = 8067;
          WEBAUTHN = 1;
        };
      };

      caddy.virtualHosts = lib.mkIf config.node.services.reverseProxy.enable {
        "news.qyrnl.com".extraConfig = ''
          import ts_host
          reverse_proxy localhost:${toString config.services.miniflux.config.PORT}
        '';
      };

      gatus.settings.endpoints = [
        (lib.fn.mkHttpServiceEndpoint "miniflux" "news.qyrnl.com")
      ];
    };
  };
}
