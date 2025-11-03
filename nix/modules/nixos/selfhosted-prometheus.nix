{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.prometheus = with lib; {
    enable = mkEnableOption "Spin up a Prometheus service";
  };

  config = let
    cfg = config.node.services.prometheus;
    inherit (flake.lib) caddy facts gatus;
  in {
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

        scrapeConfigs = let
          mkNodeExporterConfig = host: {
            targets = ["${host}.qyrnl.com:${toString config.services.prometheus.exporters.node.port}"];
            labels = {inherit host;};
          };
          mkZfsExporterConfig = host: {
            targets = ["${host}.qyrnl.com:${toString config.services.prometheus.exporters.zfs.port}"];
            labels = {inherit host;};
          };
        in [
          {
            job_name = "node_exporter";
            static_configs = builtins.map mkNodeExporterConfig [
              "bowmore"
              "dalmore"
              "fwk"
              "linode-fr"
              # "linode-jp"
              "nyx"
              "rip"
              "skl"
            ];
          }
          {
            job_name = "zfs";
            static_configs = builtins.map mkZfsExporterConfig [
              "bowmore"
              "dalmore"
              "fwk"
              "linode-fr"
              # "linode-jp"
              "nyx"
              "rip"
              "skl"
            ];
          }
          {
            job_name = "gatus";
            static_configs = [
              {targets = ["status.qyrnl.com"];}
            ];
          }
        ];
      };

      caddy.virtualHosts = caddy.mkReverseProxyConfig facts.services.prometheus;
      gatus.settings.endpoints = [
        (gatus.mkHttpServiceCheck "prometheus" {
          domain = "prometheus.qyrnl.com/-/healthy";
        })
      ];
    };
  };
}
