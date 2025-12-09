{
  config,
  lib,
  ...
}: let
  cfg = config.node.fs.zfs.snapshots;
in {
  options.node.fs.zfs.snapshots = with lib; {
    lowFrequency = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        The datasets to backup with the following policy:

        - 30 daily snapshots
        - 12 monthly snapshots
        - 2 yearly snapshots

        I.e. one month of dailies, one year of monthlies, and two yearlies.

        This policy is adequate for datasets that are occasionally written to
        (e.g. media storage).

        Datasets are backed up recursively.
      '';
    };

    highFrequency = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        The datasets to backup with the following policy:

        - 36 hourly snapshots
        - 30 daily snapshots
        - 3 monthly snapshots

        I.e. one month of dailies, one year of monthlies, and two yearlies.

        This policy is adequate for datasets that are frequently written to
        (e.g. data dirs) to support recovery of recent changes.

        Datasets are backed up recursively.
      '';
    };
  };

  config = {
    # https://github.com/jimsalterjrs/sanoid/wiki/Sanoid#options.
    # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
    services.sanoid = {
      enable = true;

      templates = {
        # Snapshot retention policy for occasionally written datasets
        # (backups/archives).
        lowFrequencyPolicy = {
          hourly = 0;
          daily = 30;
          monthly = 12;
          yearly = 2;
          autoprune = true;
          autosnap = true;
        };

        # Snapshot retention policy for frequently written datasets.
        highFrequencyPolicy = {
          hourly = 36;
          daily = 30;
          monthly = 3;
          yearly = 0;
          autoprune = true;
          autosnap = true;
        };
      };

      datasets = let
        mkLowFrequencyPolicy = dataset: {
          "${dataset}" = {
            useTemplate = ["lowFrequencyPolicy"];
            recursive = true;
            process_children_only = true;
          };
        };
        mkHighFrequencyPolicy = dataset: {
          "${dataset}" = {
            useTemplate = ["highFrequencyPolicy"];
            recursive = true;
            process_children_only = true;
          };
        };
        mapPolicy = mkConfig: datasets:
          lib.mergeAttrsList (builtins.map mkConfig datasets);
      in
        lib.mergeAttrsList [
          (mapPolicy mkLowFrequencyPolicy cfg.lowFrequency)
          (mapPolicy mkHighFrequencyPolicy cfg.highFrequency)
        ];
    };

    # Only run sanoid when ZFS datasets are mounted.
    systemd.services.sanoid = {
      after = ["local-fs.target" "zfs-mount.service"];
      wants = ["zfs-mount.service"];
    };
  };
}
