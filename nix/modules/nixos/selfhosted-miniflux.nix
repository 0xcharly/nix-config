{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.miniflux = with lib; {
    enable = mkEnableOption "Spin up a Miniflux service";
  };

  config = let
    cfg = config.node.services.miniflux;
    inherit (flake.lib) caddy facts;
  in {
    services = {
      miniflux = {
        inherit (cfg) enable;
        adminCredentialsFile = config.age.secrets."services/miniflux-admin-creds".path;
        config = {
          BASE_URL = "https://${facts.services.miniflux.domain}";
          CREATE_ADMIN = 1;
          PORT = facts.services.miniflux.port;
          WEBAUTHN = 1;
        };
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.miniflux;
    };
  };
}
