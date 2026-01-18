{
  config.services.prometheus.exporters.zfs = {
    enable = true;
    extraFlags = [ "--collector.dataset-snapshot" ];
  };
}
