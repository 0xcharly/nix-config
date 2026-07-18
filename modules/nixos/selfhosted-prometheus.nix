{ self, ... }:
{
  flake.nixosModules.selfhosted-prometheus =
    { config, lib, ... }:
    {
      options.node.services.prometheus = with lib; {
        enable = mkEnableOption "Spin up a Prometheus service";
      };

      config =
        let
          cfg = config.node.services.prometheus;
          inherit (self.lib) facts inventory;
        in
        {
          node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
            prometheus = {
              owner = "prometheus";
              group = "prometheus";
              mode = "0700";
            };
          };

          services = {
            prometheus = {
              inherit (cfg) enable;
              stateDir = "prometheus";
              webExternalUrl = "https://${facts.services.prometheus.domain}";
              # Long enough to read monthly transfer windows (Linode 1 TB/mo
              # egress allowance) off the network-transfer dashboard.
              retentionTime = "180d";

              scrapeConfigs =
                let
                  mkNodeExporterConfig = host: {
                    targets = [ "${host}.qyrnl.com:${toString config.services.prometheus.exporters.node.port}" ];
                    labels = { inherit host; };
                  };
                  mkZfsExporterConfig = host: {
                    targets = [ "${host}.qyrnl.com:${toString config.services.prometheus.exporters.zfs.port}" ];
                    labels = { inherit host; };
                  };
                  mkSmartctlExporterConfig = host: {
                    targets = [ "${host}.qyrnl.com:${toString config.services.prometheus.exporters.smartctl.port}" ];
                    labels = { inherit host; };
                  };
                  mkScrapeConfigs = lib.mapAttrsToList (
                    job_name: static_configs: {
                      inherit job_name static_configs;
                    }
                  );
                  mkBlackboxJob = name: prober_host: module: targets: {
                    job_name = name;
                    metrics_path = "/probe";
                    params.module = [ module ];
                    static_configs = [
                      {
                        inherit targets;
                        labels.prober = prober_host;
                      }
                    ];
                    relabel_configs = [
                      {
                        source_labels = [ "__address__" ];
                        target_label = "__param_target";
                      }
                      {
                        source_labels = [ "__param_target" ];
                        target_label = "instance";
                      }
                      {
                        target_label = "__address__";
                        replacement = "${prober_host}.qyrnl.com:${toString config.services.prometheus.exporters.blackbox.port}";
                      }
                    ];
                  };
                in
                mkScrapeConfigs {
                  # Scrape Gatus directly over the tailnet rather than through the
                  # Caddy reverse proxy: the availability pipeline must not depend on
                  # the proxy being up.
                  gatus = lib.singleton {
                    targets = [ "${facts.services.gatus.host}:${toString facts.services.gatus.port}" ];
                    labels.host = builtins.head (lib.splitString "." facts.services.gatus.host);
                  };
                  servers_system_stats = map mkNodeExporterConfig inventory.servers;
                  servers_zfs_stats = map mkZfsExporterConfig inventory.servers;
                  workstations_system_stats = map mkNodeExporterConfig inventory.workstations;
                  workstations_zfs_stats = map mkZfsExporterConfig inventory.workstations;
                  smartctl_stats = map mkSmartctlExporterConfig inventory.smartctl;
                }
                ++ [
                  {
                    job_name = "prometheus";
                    static_configs = [
                      {
                        targets = [ "localhost:9090" ];
                        labels.host = "site-jp";
                      }
                    ];
                  }
                  (mkBlackboxJob "blackbox_icmp_from_jp" "site-jp" "icmp" [
                    "gate-jp.qyrnl.com"
                    "jump-jp.qyrnl.com"
                    "gate-fr.qyrnl.com"
                    "site-fr.qyrnl.com"
                    "node-skl.qyrnl.com"
                  ])
                  (mkBlackboxJob "blackbox_icmp_from_fr" "site-fr" "icmp" [
                    "site-jp.qyrnl.com"
                    "gate-jp.qyrnl.com"
                    "jump-jp.qyrnl.com"
                    "gate-fr.qyrnl.com"
                  ])
                  (mkBlackboxJob "blackbox_http_from_jp" "site-jp" "http_2xx" [ "https://status.qyrnl.com" ])
                  (mkBlackboxJob "blackbox_http_from_fr" "site-fr" "http_2xx" [
                    "https://graphs.qyrnl.com"
                    "https://status.qyrnl.com"
                  ])
                ];
            };
          };
        };
    };
}
