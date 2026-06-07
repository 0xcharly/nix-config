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
        };
    };
}
