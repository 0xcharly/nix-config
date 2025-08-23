{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.prometheus.exporters.node;
in {
  options.node.services.prometheus.exporters.node.enable = lib.mkEnableOption "Whether to export node metrics to Prometheus.";

  config.services.prometheus.exporters.node = {
    inherit (cfg) enable;
    enabledCollectors = ["systemd"];
  };
}
