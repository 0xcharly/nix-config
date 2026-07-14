{
  flake.nixosModules.prometheus-exporters-smartctl = {
    config = {
      services.prometheus.exporters.smartctl.enable = true;
      # SATA drive temperatures via hwmon (node_hwmon_temp_celsius).
      boot.kernelModules = [ "drivetemp" ];
    };
  };
}
