{ self, ... }:
{
  # Node exporter's default-on btrfs collector already ships allocation and
  # device-error metrics; what it misses is scrub results, which only surface
  # in `btrfs scrub status`. Publish them through the node exporter textfile
  # collector (directory provisioned by prometheus-exporters-node, imported by
  # every host that imports this module). No enable option: importing the
  # module enables it — reporting is mandatory on btrfs hosts.
  flake.nixosModules.prometheus-exporters-btrfs =
    { pkgs, ... }:
    {
      systemd.services.prometheus-btrfs-scrub-textfile = {
        description = "Write btrfs scrub metrics for the node exporter textfile collector";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = self.lib.builders.mkShellApplication pkgs {
            name = "prometheus-btrfs-scrub-textfile";
            runtimeInputs = [
              pkgs.bc
              pkgs.btrfs-progs
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
            ];
            text = ''
              set -euo pipefail
              dir=/var/lib/prometheus-node-exporter/textfile
              status=$(btrfs scrub status /)
              {
                echo '# HELP btrfs_scrub_running 1 while a scrub is in progress.'
                echo '# TYPE btrfs_scrub_running gauge'
                echo '# HELP btrfs_scrub_start_timestamp_seconds Start time of the last scrub.'
                echo '# TYPE btrfs_scrub_start_timestamp_seconds gauge'
                echo '# HELP btrfs_scrub_errors Errors found by the last scrub.'
                echo '# TYPE btrfs_scrub_errors gauge'
                # Never-scrubbed (every fresh install until the first monthly
                # timer run): no "Scrub started:" line — report only
                # btrfs_scrub_running 0 and exit 0, or this oneshot fails
                # every 15 minutes on every newly migrated host.
                if ! grep -q '^Scrub started:' <<<"$status"; then
                  echo 'btrfs_scrub_running{mountpoint="/"} 0'
                else
                  running=0
                  if grep -q '^Status:[[:space:]]*running' <<<"$status"; then
                    running=1
                  fi
                  started=$(grep '^Scrub started:' <<<"$status" | sed 's/^Scrub started:[[:space:]]*//')
                  errors=0
                  summary=$(grep '^Error summary:' <<<"$status" | sed 's/^Error summary:[[:space:]]*//')
                  if [ -n "$summary" ] && [ "$summary" != "no errors found" ]; then
                    # Sum the k=N counts, e.g. "csum=3 read=1".
                    errors=$(grep -o '[a-z_]*=[0-9]*' <<<"$summary" | cut -d= -f2 | paste -sd+ - | bc)
                  fi
                  echo "btrfs_scrub_running{mountpoint=\"/\"} $running"
                  echo "btrfs_scrub_start_timestamp_seconds{mountpoint=\"/\"} $(date -d "$started" +%s)"
                  echo "btrfs_scrub_errors{mountpoint=\"/\"} $errors"
                fi
              } > "$dir/btrfs-scrub.prom.tmp"
              mv "$dir/btrfs-scrub.prom.tmp" "$dir/btrfs-scrub.prom"
            '';
          };
        };
      };

      systemd.timers.prometheus-btrfs-scrub-textfile = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "15min";
        };
      };
    };
}
