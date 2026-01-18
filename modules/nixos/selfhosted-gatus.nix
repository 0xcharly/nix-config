{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  options.node.services.gatus = with lib; {
    enable = mkEnableOption "Spin up a Gatus service";
  };

  config =
    let
      cfg = config.node.services.gatus;
      inherit (flake.lib) facts;
    in
    {
      services = {
        gatus = {
          inherit (cfg) enable;
          environmentFile = config.age.secrets."services/gatus.env".path;
          settings = {
            web = { inherit (facts.services.gatus) port; };

            metrics = true; # Exposes metrics for Prometheus.
            alerting = {
              # FIXME: This fails with:
              #   dial tcp <ip>:587: i/o timeout
              email = {
                to = "mail@qyrnl.com";
                from = "status@qyrnl.com";
                username = "status@qyrnl.com";
                password = "$EMAIL_TOKEN";
                host = "smtp.protonmail.ch";
                port = 587;
                client.insecure = false;
                default-alert = {
                  enabled = false;
                  description = "Status Alert";
                  send-on-resolved = true;
                  failure-threshold = 3;
                  success-threshold = 2;
                };
              };
              gotify = {
                server-url = "https://${facts.services.gotify.domain}";
                token = "$GOTIFY_TOKEN";
                body = builtins.toJSON {
                  type = "note";
                  title = "Gatus [ALERT_TRIGGERED_OR_RESOLVED]: [ENDPOINT_NAME]";
                  body = "[ALERT_DESCRIPTION] - [ENDPOINT_URL]";
                };
                default-alert = {
                  enabled = true;
                  description = "Status Alert";
                  send-on-resolved = true;
                  failure-threshold = 3;
                  success-threshold = 2;
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
      };
    };
}
