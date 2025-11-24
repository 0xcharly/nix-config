{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.gatus = with lib; {
    enable = mkEnableOption "Spin up a Gatus service";
  };

  config = let
    cfg = config.node.services.gatus;
    inherit (flake.lib) caddy facts;
  in {
    services = {
      gatus = {
        inherit (cfg) enable;
        environmentFile = config.age.secrets."services/gatus.env".path;
        settings = {
          web = {inherit (facts.services.gatus) port;};

          metrics = true; # Exposes metrics for Prometheus.
          alerting = {
            gotify = {
              server-url = "https://${facts.services.gotify.domain}";
              token = "$GOTIFY_TOKEN";
              body = builtins.toJSON {
                type = "note";
                title = "Gatus [ALERT_TRIGGERED_OR_RESOLVED]: [ENDPOINT_NAME]";
                body = "[ALERT_DESCRIPTION] - [ENDPOINT_URL]";
              };
              default-alert = {
                description = "Status Change";
                send-on-resolved = true;
                failure-threshold = 5;
                success-threshold = 3;
              };
            };
          };
          storage = {
            type = "sqlite";
            path = "/var/lib/gatus/gatus.db";
          };
          ui = {
            title = "Status";
            header = "Status";
            description = "Powered by Gatus";
          };
        };
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.gatus;
    };
  };
}
