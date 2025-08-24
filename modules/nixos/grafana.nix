{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.grafana;
in {
  options.node.services.grafana.enable = lib.mkEnableOption "Whether to spin up a Grafana service.";

  config = {
    services = {
      grafana = {
        inherit (cfg) enable;
        settings = {
          server = {
            http_port = 3333;
            enforce_domain = true;
            enable_gzip = true;
            domain = "graphs.qyrnl.com";
          };
          auth.disable_login_form = true;
          "auth.anonymous" = {
            enabled = true;
            org_role = "Admin";
          };
        };

        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = config.services.prometheus.webExternalUrl;
              isDefault = true;
              editable = false;
            }
          ];
        };
      };

      gatus.settings.endpoints = [
        (lib.fn.mkApiEndpoint "grafana" "graphs.qyrnl.com/api/health" ["[BODY].database == ok"])
      ];

      caddy.virtualHosts."graphs.qyrnl.com".extraConfig = ''
        import ts_host
        reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      '';
    };
  };
}
