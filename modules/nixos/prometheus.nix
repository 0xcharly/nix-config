{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.prometheus.server;
in {
  options.node.services.prometheus.server.enable = lib.mkEnableOption "Whether to spin up a Prometheus server.";

  config = {
    services = {
      prometheus = {
        inherit (cfg) enable;
        webExternalUrl = "https://prometheus.qyrnl.com";

        scrapeConfigs = let
          makeNodeExporterConfig = host: address: {
            targets = ["${address}:${toString config.services.prometheus.exporters.node.port}"];
            labels = {inherit host;};
          };
          makeZfsExporterConfig = host: address: {
            targets = ["${address}:${toString config.services.prometheus.exporters.zfs.port}"];
            labels = {inherit host;};
          };
        in [
          {
            job_name = "node_exporter";
            static_configs = [
              (makeNodeExporterConfig "heimdall" "heimdall.qyrnl.com")
              (makeNodeExporterConfig "helios" "helios.qyrnl.com")
              (makeNodeExporterConfig "linode" "linode.qyrnl.com")
              (makeNodeExporterConfig "selene" "selene.qyrnl.com")
              (makeNodeExporterConfig "skullkid" "skullkid.qyrnl.com")
            ];
          }
          {
            job_name = "zfs";
            static_configs = [
              (makeZfsExporterConfig "helios" "helios.qyrnl.com")
              (makeZfsExporterConfig "selene" "selene.qyrnl.com")
              (makeZfsExporterConfig "skullkid" "skullkid.qyrnl.com")
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

      caddy.virtualHosts."prometheus.qyrnl.com".extraConfig = ''
        import ts_host
        reverse_proxy localhost:${toString config.services.prometheus.port}
      '';
    };
  };
}
