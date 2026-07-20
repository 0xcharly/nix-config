{ self, ... }:
{
  flake.nixosModules.selfhosted-grafana =
    { config, lib, ... }:
    {
      options.node.services.grafana = with lib; {
        enable = mkEnableOption "Spin up a Grafana service";
      };

      config =
        let
          cfg = config.node.services.grafana;
          inherit (self.lib) facts;
        in
        {
          node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
            grafana = {
              owner = "grafana";
              group = "grafana";
              mode = "0700";
            };
          };

          services.grafana = {
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
              # Land on the homelab overview instead of Grafana's onboarding page.
              dashboards.default_home_dashboard_path = "${./grafana-dashboards}/home.json";
              # Grafana's secret key doesn't have a default value anymore.
              # Please generate your own and use a file-provider on this option!
              # See also https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#secret_key
              # for more information.
              #
              # See https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-database-encryption/#re-encrypt-secrets on how to re-encrypt.
              #
              # As stated in the NixOS changelog for 26.05, there's no official
              # way to rotate. Either hard-code the old key if your setup
              # doesn't have any secrets in the DB that need special protection
              # or perform a rotation with a 3rd-party tool.
              # (https://github.com/erooke/grafana-secretkey-rotation-tool/tree/d9dc788902fa5185e15cb15ce6129f7237ab6138).
              security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
            };

            provision = {
              enable = true;
              datasources.settings = {
                # The datasource row pre-dates the pinned uid: Grafana's
                # provisioner updates by uid and fails startup with
                # "data source not found" when the DB row carries the older
                # auto-generated uid. Deleting by name first makes the
                # re-create (with the pinned uid) idempotent.
                deleteDatasources = [
                  {
                    name = "Prometheus";
                    orgId = 1;
                  }
                ];
                datasources = [
                  {
                    name = "Prometheus";
                    uid = "prometheus";
                    type = "prometheus";
                    url = config.services.prometheus.webExternalUrl;
                    isDefault = true;
                    editable = false;
                  }
                  {
                    name = "Blocky query log";
                    uid = "blocky-query-log";
                    type = "postgres";
                    # Loopback TCP: the pg_hba trust entry for the blocky user
                    # is host-scoped (selfhosted-blocky-query-log), and peer
                    # auth would not apply to the grafana OS user anyway.
                    url = "127.0.0.1:${toString facts.services.blocky.query-log.port}";
                    user = facts.services.blocky.query-log.user;
                    jsonData = {
                      inherit (facts.services.blocky.query-log) database;
                      sslmode = "disable";
                    };
                    editable = false;
                  }
                ];
              };
              dashboards.settings.providers = [
                {
                  name = "nix-config";
                  # Copied to the store: dashboards ship with the closure;
                  # edit the JSON and redeploy site-jp to update.
                  options.path = ./grafana-dashboards;
                }
              ];
            };
          };
        };
    };
}
