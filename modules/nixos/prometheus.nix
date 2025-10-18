{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.prometheus.server;
in {
  options.node.services.prometheus.server.enable = lib.mkEnableOption "Whether to spin up a Prometheus service.";

  config = {
    services = {
      prometheus = {
        inherit (cfg) enable;
        webExternalUrl = "https://prometheus.qyrnl.com";

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
              "heimdall"
              "helios"
              "linode"
              "linode-fr"
              "linode-jp"
              "skl"
            ];
          }
          {
            job_name = "zfs";
            static_configs = builtins.map mkZfsExporterConfig [
              "bowmore"
              "dalmore"
              "fwk"
              "helios"
              "linode"
              "linode-fr"
              "linode-jp"
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

      gatus.settings.endpoints = [
        (lib.fn.mkHttpServiceEndpoint "prometheus" "prometheus.qyrnl.com/-/healthy")
      ];

      caddy.virtualHosts = lib.mkIf config.node.services.reverseProxy.enable {
        "prometheus.qyrnl.com".extraConfig = ''
          import ts_host
          reverse_proxy localhost:${toString config.services.prometheus.port}
        '';
      };
    };
  };
}
