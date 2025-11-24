{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.grafana = with lib; {
    enable = mkEnableOption "Spin up a Grafana service";
  };

  config = let
    cfg = config.node.services.grafana;
    inherit (flake.lib) caddy facts;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      grafana = {
        owner = "grafana";
        group = "grafana";
        mode = "0700";
      };
    };

    services = {
      grafana = {
        inherit (cfg) enable;
        dataDir = config.node.fs.zfs.zpool.root.datadirs.grafana.absolutePath;
        settings = {
          server = {
            domain = facts.services.grafana.domain;
            enable_gzip = true;
            enforce_domain = true;
            http_addr = "0.0.0.0";
            http_port = facts.services.grafana.port;
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

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.grafana;
    };
  };
}
