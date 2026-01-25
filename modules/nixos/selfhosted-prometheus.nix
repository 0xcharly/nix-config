{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  options.node.services.prometheus = with lib; {
    enable = mkEnableOption "Spin up a Prometheus service";
  };

  config =
    let
      cfg = config.node.services.prometheus;
      inherit (flake.lib) facts inventory;
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
              mkScrapeConfigs = lib.mapAttrsToList (
                job_name: static_configs: {
                  inherit job_name static_configs;
                }
              );
            in
            mkScrapeConfigs {
              gatus = lib.singleton { targets = [ facts.services.gatus.domain ]; };
              servers_system_stats = map mkNodeExporterConfig inventory.servers;
              servers_zfs_stats = map mkZfsExporterConfig inventory.servers;
              workstations_system_stats = map mkNodeExporterConfig inventory.workstations;
              workstations_zfs_stats = map mkZfsExporterConfig inventory.workstations;
            };
        };
      };
    };
}
