{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.gatus;

  # TODO(unstable): Switch to pkgs'.gatus when this lands on unstable.
  # https://github.com/NixOS/nixpkgs/pull/412797
  package = pkgs.gatus.overrideAttrs rec {
    version = "5.23.2";

    src = pkgs.fetchFromGitHub {
      owner = "TwiN";
      repo = "gatus";
      rev = "v${version}";
      hash = "sha256-b/UQwwyspOKrW9mRoq0zJZ41lNLM+XvGFlpxz+9ZMco=";
    };

    vendorHash = "sha256-jMNsd7AiWG8vhUW9cLs5Ha2wmdw9SHjSDXIypvCKYqk=";
  };
in {
  options.node.services.gatus.enable = lib.mkEnableOption "Whether to spin up a Gatus server.";

  config = {
    services = {
      gatus = {
        inherit (cfg) enable;
        # TODO(25.11): Enable new UI. Remove once it lands on stable.
        inherit package;
        environmentFile = config.age.secrets."services/gatus.env".path;
        settings = {
          metrics = true; # Exposes metrics for Prometheus.
          alerting = {
            gotify = {
              server-url = "https://push.qyrnl.com";
              token = "$GOTIFY_TOKEN";
              body = ''{"type":"note","title":"Gatus [ALERT_TRIGGERED_OR_RESOLVED]: [ENDPOINT_NAME]","body":"[ALERT_DESCRIPTION] - [ENDPOINT_URL]"}'';
              default-alert = {
                description = "Status Change";
                send-on-resolved = true;
                failure-threshold = 5;
                success-thershold = 3;
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
          endpoints = builtins.map lib.fn.mkPingHomelabEndpoint [
            "heimdall"
            "helios"
            "linode"
            "selene"
            "skullkid"
          ];
        };
      };

      caddy.virtualHosts."status.qyrnl.com".extraConfig = ''
        import ts_host
        reverse_proxy localhost:${toString config.services.gatus.settings.web.port}
      '';
    };

    # TODO(25.11): Remove once this lands on stable.
    # https://github.com/NixOS/nixpkgs/pull/415879
    systemd.services.gatus = lib.mkIf cfg.enable {
      serviceConfig = {
        # See https://github.com/prometheus-community/pro-bing#linux.
        AmbientCapabilities = "CAP_NET_RAW";
        CapabilityBoundingSet = "CAP_NET_RAW";
        NoNewPrivileges = true;
      };
    };
  };
}
