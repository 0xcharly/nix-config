{
  config,
  lib,
  ...
}: let
  cfg = config.modules.system.roles.nas;
in
  lib.mkIf cfg.enable {
    # https://github.com/jimsalterjrs/sanoid/wiki/Sanoid#options.
    # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#snapshot-management-with-sanoid
    services.sanoid = {
      enable = true;

      # Snapshot retention policy for backups/archives.
      templates.archive = {
        hourly = 0;
        daily = 30;
        monthly = 12;
        yearly = 2;
        autoprune = true;
        autosnap = lib.fn.isTrue cfg.primary; # Only create snapshot on the primary.
      };

      # Snapshot retention policy for user files.
      templates.users = {
        hourly = 36;
        daily = 30;
        monthly = 3;
        yearly = 0;
        autoprune = true;
        autosnap = lib.fn.isTrue cfg.primary; # Only create snapshot on the primary.
      };

      datasets = let
        mkArchivePolicy = dataset: {
          "${dataset}" = {
            useTemplate = ["archive"];
            recursive = true;
            process_children_only = true;
          };
        };
        mkUsersPolicy = dataset: {
          "${dataset}" = {
            useTemplate = ["users"];
            recursive = true;
            process_children_only = true;
          };
        };
        mapPolicy = mkConfig: datasets:
          lib.mergeAttrsList (builtins.map mkConfig datasets);
      in
        lib.mergeAttrsList [
          # Backup every datasets under /tank/backups (but not the root dataset
          # itself) with the `archive` policy.
          (mapPolicy mkArchivePolicy [
            "tank/backups"
          ])
          # Backup every datasets under /tank/ayako and /tank/delay (but not the
          # root datasets themselves) with the `users` policy.
          (mapPolicy mkUsersPolicy [
            "tank/ayako"
            "tank/delay"
          ])
        ];
    };

    # Only run sanoid when ZFS datasets are mounted and Tailscale network is up.
    systemd.services.sanoid = {
      after = ["network-online.target" "tailscaled.service" "zfs-mount-tank.service"];
      requires = ["network-online.target" "tailscaled.service" "zfs-mount-tank.service"];
      wants = ["tailscaled.service"];
    };
  }
