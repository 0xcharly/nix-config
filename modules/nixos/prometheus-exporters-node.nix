{
  config.services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    # node_exporter  --help
    extraFlags = [
      "--collector.ethtool"
      "--collector.softirqs"
      "--collector.tcpstat"
      "--collector.wifi"
    ];
  };
}
