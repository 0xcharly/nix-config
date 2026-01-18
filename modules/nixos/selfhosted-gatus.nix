{ flake, ... }:
{
  config,
  lib,
  pkgs,
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

          package = pkgs.gatus.overrideAttrs (attrs: {
            patches = (attrs.patches or [ ]) ++ [
              ./0001-feat-pushover-add-support-for-custom-endpoint-URLs.patch
            ];
          });

          environmentFile = config.age.secrets."services/gatus.env".path;
          settings = {
            web = { inherit (facts.services.gatus) port; };

            metrics = true; # Exposes metrics for Prometheus.
            alerting = {
              email = rec {
                to = "mail@qyrnl.com";
                from = "status@qyrnl.com";
                username = from;
                password = "$EMAIL_TOKEN";
                host = "smtp.protonmail.ch";
                port = 587;
                client.insecure = false;
                default-alert = flake.lib.gatus.mkAlertParams {
                  # FIXME: Linode blocks outgoing SMTP connections
                  #   https://techdocs.akamai.com/cloud-computing/docs/send-email
                  #   https://www.linode.com/docs/guides/running-a-mail-server/
                  #   gomail fails with: dial tcp <ip>:587: i/o timeout
                  enabled = false;
                  failure-threshold = 2;
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
                default-alert = flake.lib.gatus.mkAlertParams { failure-threshold = 2; };
              };
              pushover = {
                endpoint-url = "https://via.msg.taxi/1/messages.json";
                application-token = "$MSGTAXI_TOKEN";
                user-key = "$MSGTAXI_USER_KEY";
                default-alert = flake.lib.gatus.mkAlertParams { failure-threshold = 2; };
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
