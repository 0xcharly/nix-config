{ self, ... }:
{
  flake.nixosModules.prometheus-exporters-node =
    { pkgs, ... }:
    {
      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        # node_exporter  --help
        extraFlags = [
          "--collector.ethtool"
          "--collector.softirqs"
          "--collector.tcpstat"
          "--collector.wifi"
          "--collector.textfile.directory=/var/lib/prometheus-node-exporter/textfile"
        ];
      };

      systemd.tmpfiles.rules = [ "d /var/lib/prometheus-node-exporter/textfile 0755 root root -" ];

      # Publishes NixOS generation state (pending reboot, last switch time)
      # through the node exporter textfile collector.
      systemd.services.prometheus-nixos-textfile = {
        description = "Write NixOS generation metrics for the node exporter textfile collector";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = self.lib.builders.mkShellApplication pkgs {
            name = "prometheus-nixos-textfile";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              set -euo pipefail
              dir=/var/lib/prometheus-node-exporter/textfile
              pending=0
              if [ "$(readlink -f /run/booted-system/kernel)" != "$(readlink -f /run/current-system/kernel)" ] \
                || [ "$(readlink -f /run/booted-system/initrd)" != "$(readlink -f /run/current-system/initrd)" ]; then
                pending=1
              fi
              switch_ts=$(stat -c %Y /nix/var/nix/profiles/system)
              {
                echo "# HELP nixos_pending_reboot 1 when booted kernel/initrd differ from the current system generation."
                echo "# TYPE nixos_pending_reboot gauge"
                echo "nixos_pending_reboot $pending"
                echo "# HELP nixos_system_profile_last_switch_timestamp_seconds mtime of /nix/var/nix/profiles/system."
                echo "# TYPE nixos_system_profile_last_switch_timestamp_seconds gauge"
                echo "nixos_system_profile_last_switch_timestamp_seconds $switch_ts"
              } > "$dir/nixos.prom.tmp"
              mv "$dir/nixos.prom.tmp" "$dir/nixos.prom"
            '';
          };
        };
      };

      systemd.timers.prometheus-nixos-textfile = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "5min";
        };
      };
    };
}
