{
  config,
  lib,
  ...
}: let
  cfg = config.node.services.prometheus.exporters.zfs;
in {
  options.node.services.prometheus.exporters.zfs.enable = lib.mkEnableOption "Whether to export ZFS metrics to Prometheus.";

  config.services.prometheus.exporters.zfs = {
    inherit (cfg) enable;
    extraFlags = ["--collector.dataset-snapshot"];
  };
}
