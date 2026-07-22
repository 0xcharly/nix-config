{ self, ... }:
{
  flake.nixosModules.prometheus-exporters-zfs =
    { config, pkgs, ... }:
    {
      services.prometheus.exporters.zfs = {
        enable = true;
        extraFlags = [ "--collector.dataset-snapshot" ];
      };

      # zfs_exporter only exposes pool/dataset properties; scrub progress and
      # error counters only surface in `zpool status`. Publish them through
      # the node exporter textfile collector (directory provisioned by
      # prometheus-exporters-node, imported by every host that imports this
      # module).
      systemd.services.prometheus-zfs-scrub-textfile = {
        description = "Write ZFS scrub metrics for the node exporter textfile collector";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = self.lib.builders.mkShellApplication pkgs {
            name = "prometheus-zfs-scrub-textfile";
            runtimeInputs = [
              config.boot.zfs.package
              pkgs.coreutils
              pkgs.jq
            ];
            text = ''
              set -euo pipefail
              dir=/var/lib/prometheus-node-exporter/textfile
              {
                echo '# HELP zfs_pool_scrub_state Last scrub state: 0 never/unknown, 1 scanning, 2 finished, 3 canceled.'
                echo '# TYPE zfs_pool_scrub_state gauge'
                echo '# HELP zfs_pool_scrub_start_timestamp_seconds Start time of the last scrub; 0 when never scrubbed.'
                echo '# TYPE zfs_pool_scrub_start_timestamp_seconds gauge'
                echo '# HELP zfs_pool_scrub_end_timestamp_seconds End time of the last completed scrub; 0 when never scrubbed or still running.'
                echo '# TYPE zfs_pool_scrub_end_timestamp_seconds gauge'
                echo '# HELP zfs_pool_scrub_errors Errors found by the last scrub.'
                echo '# TYPE zfs_pool_scrub_errors gauge'
                echo '# HELP zfs_pool_data_errors Known data errors in the pool (zpool status error count).'
                echo '# TYPE zfs_pool_data_errors gauge'
                echo '# HELP zfs_pool_read_errors Read errors aggregated at the root vdev.'
                echo '# TYPE zfs_pool_read_errors gauge'
                echo '# HELP zfs_pool_write_errors Write errors aggregated at the root vdev.'
                echo '# TYPE zfs_pool_write_errors gauge'
                echo '# HELP zfs_pool_checksum_errors Checksum errors aggregated at the root vdev.'
                echo '# TYPE zfs_pool_checksum_errors gauge'
                # scan_stats only describes the most recent scan; gate on
                # function == SCRUB so a resilver zeroes the scrub fields
                # instead of impersonating a clean scrub.
                zpool status -j --json-int | jq -r '
                  def code: {"NONE":0,"SCANNING":1,"FINISHED":2,"CANCELED":3}[.] // 0;
                  .pools // {} | to_entries[] | .key as $pool | .value
                  | ((.scan_stats // {}) | if .function == "SCRUB" then . else {} end) as $scan
                  | (.vdevs[$pool] // {}) as $root
                  | "zfs_pool_scrub_state{pool=\"\($pool)\"} \($scan.state // "NONE" | code)",
                    "zfs_pool_scrub_start_timestamp_seconds{pool=\"\($pool)\"} \($scan.start_time // 0)",
                    "zfs_pool_scrub_end_timestamp_seconds{pool=\"\($pool)\"} \($scan.end_time // 0)",
                    "zfs_pool_scrub_errors{pool=\"\($pool)\"} \($scan.errors // 0)",
                    "zfs_pool_data_errors{pool=\"\($pool)\"} \(.error_count // 0)",
                    "zfs_pool_read_errors{pool=\"\($pool)\"} \($root.read_errors // 0)",
                    "zfs_pool_write_errors{pool=\"\($pool)\"} \($root.write_errors // 0)",
                    "zfs_pool_checksum_errors{pool=\"\($pool)\"} \($root.checksum_errors // 0)"
                '
              } > "$dir/zfs-scrub.prom.tmp"
              mv "$dir/zfs-scrub.prom.tmp" "$dir/zfs-scrub.prom"
            '';
          };
        };
      };

      systemd.timers.prometheus-zfs-scrub-textfile = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "15min";
        };
      };
    };
}
