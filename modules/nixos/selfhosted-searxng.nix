{flake, ...}: {
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.services.searxng = with lib; {
    enable = mkEnableOption "Spin up a SearXNG service";
  };

  config = let
    cfg = config.node.services.searxng;
    inherit (flake.lib) facts;
  in {
    services.searx = {
      inherit (cfg) enable;
      package = pkgs.searxng;

      environmentFile = config.age.secrets."services/searxng.env".path;
      redisCreateLocally = true;

      settings = {
        general = {
          # Open /metrics endpoint for Prometheus.
          enable_metrics = true;
          open_metrics = "@METRICS_PASSWD@";
        };

        search.autocomplete = "duckduckgo";

        server = {
          base_url = "https://${facts.services.search.domain}";
          bind_address = "0.0.0.0";
          inherit (facts.services.search) port;

          secret_key = "@SECRET_KEY@";
          limiter = false;
          public_instance = false;

          default_http_headers = {
            X-Content-Type-Options = "nosniff";
            X-XSS-Protection = "1; mode=block";
            X-Download-Options = "noopen";
            X-Robots-Tag = "noindex, nofollow";
            Referrer-Policy = "no-referrer";
          };
        };
      };
    };
  };
}
