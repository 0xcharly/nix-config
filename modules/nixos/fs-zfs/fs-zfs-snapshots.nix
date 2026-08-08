{
  flake.nixosModules.fs-zfs-snapshots =
    { config, lib, ... }:
    let
      cfg = config.node.fs.zfs.snapshots;

      # Freshness thresholds for `sanoid --monitor-snapshots`
      # (fs-zfs-snapshots-check). The primary uses sanoid's defaults (hourly
      # 90m/360m, daily 28h/32h, monthly 32d/40d). On replicas snapshots
      # arrive in one daily replication batch, so freshness is bounded by
      # the replication cadence instead: just before the next run the newest
      # received hourly is ~24h old and the newest daily ~46h. Warn past one
      # transfer-delay margin, crit past roughly one missed replication —
      # which turns the replica-side monitor into an end-to-end RPO check.
      replicaMonitorThresholds = {
        hourly_warn = "26h";
        hourly_crit = "50h";
        daily_warn = "50h";
        daily_crit = "74h";
        # Monthlies are taken on the 1st and replicated within a day: the
        # default 32d warn would trip after 31-day months.
        monthly_warn = "33d";
      };
    in
    {
      options.node.fs.zfs.snapshots = with lib; {
        daily = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            The datasets to backup with the following policy:

            - 30 daily snapshots
            - 12 monthly snapshots
            - 2 yearly snapshots

            I.e. one month of dailies, one year of monthlies, and two yearlies.

            This policy is adequate for datasets that are occasionally written to
            (e.g. media storage).

            Datasets are snapshotted individually (non-recursive).
          '';
        };

        hourly = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            The datasets to backup with the following policy:

            - 36 hourly snapshots
            - 30 daily snapshots
            - 12 monthly snapshots
            - 2 yearly snapshots

            I.e. 36 hours of hourlies, one month of dailies, one year of monthlies,
            and two yearlies.

            This policy is adequate for datasets that are frequently written to
            (e.g. data dirs) to support recovery of recent changes.

            Datasets are snapshotted individually (non-recursive).
          '';
        };

        autosnap = mkOption {
          type = types.bool;
          description = ''
            Whether sanoid takes new snapshots. No default on purpose: each host
            states its role explicitly. Set to `true` on the snapshot primary;
            set to `false` on replication replicas, where received snapshots are
            only pruned per the retention templates, never created locally.
          '';
        };
      };

      config = {
        # https://github.com/jimsalterjrs/sanoid/wiki/Sanoid#options
        # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
        services.sanoid = {
          enable = true;

          templates = {
            # Snapshot retention policy for occasionally written datasets (backups/archives)
            daily = {
              hourly = 0;
              daily = 30;
              monthly = 12;
              yearly = 2;
              autoprune = true;
              inherit (cfg) autosnap;
            }
            // lib.optionalAttrs (!cfg.autosnap) replicaMonitorThresholds;

            # Snapshot retention policy for frequently written datasets
            hourly = {
              hourly = 36;
              daily = 30;
              monthly = 12;
              yearly = 2;
              autoprune = true;
              inherit (cfg) autosnap;
            }
            // lib.optionalAttrs (!cfg.autosnap) replicaMonitorThresholds;
          };

          datasets =
            let
              mkDailyPolicy = dataset: {
                "${dataset}" = {
                  useTemplate = [ "daily" ];
                  recursive = false;
                  process_children_only = false;
                };
              };
              mkHourlyPolicy = dataset: {
                "${dataset}" = {
                  useTemplate = [ "hourly" ];
                  recursive = false;
                  process_children_only = false;
                };
              };
              mapPolicy = mkConfig: datasets: lib.mergeAttrsList (map mkConfig datasets);
            in
            lib.mergeAttrsList [
              (mapPolicy mkDailyPolicy cfg.daily)
              (mapPolicy mkHourlyPolicy cfg.hourly)
            ];
        };

        # Only run sanoid when ZFS datasets are mounted
        systemd.services.sanoid = {
          after = [
            "local-fs.target"
            "zfs-mount.service"
          ];
          wants = [ "zfs-mount.service" ];
        };
      };
    };
}
