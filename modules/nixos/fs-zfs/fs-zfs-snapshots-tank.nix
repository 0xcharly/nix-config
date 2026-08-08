{ self, ... }:
{
  # Canonical snapshot policy for the `tank` pool (layout defined in
  # fs-zfs-backup-minisforum-n5.nix). Imported by the primary (snapshots +
  # prune) and by replicas (prune only, via `snapshots.autosnap = false`).
  flake.nixosModules.fs-zfs-snapshots-tank =
    { config, lib, ... }:
    let
      # Empty structural parents. Excluded from replication
      # (fs-zfs-replication-primary), but still snapshotted locally so every
      # dataset in the pool carries an explicit policy (see the coverage
      # assertion below).
      containers = [
        "tank/ayako"
        "tank/backups"
        "tank/delay"
        "tank/delay/forge"
      ];
    in
    {
      imports = with self.nixosModules; [ fs-zfs-snapshots ];

      config = {
        # Every dataset in the pool must have an explicit snapshot policy:
        # syncoid --no-sync-snap exits non-zero for any recursed dataset
        # without snapshots, and a policy-less dataset is otherwise a silent
        # data-protection gap. Ground truth is the disko layout, so adding a
        # dataset without deciding its policy fails evaluation.
        assertions =
          let
            cfg = config.node.fs.zfs.snapshots;
            declared = cfg.hourly ++ cfg.daily;
            # Keys are pool-relative ("delay/beans"); qualify to match the
            # "tank/…" names used by the policy lists. disko injects a
            # `__root` placeholder key for the pool's root dataset (`tank`
            # itself, skipped by syncoid --skip-parent) — exclude it.
            pool = map (name: "tank/${name}") (
              lib.filter (name: name != "__root") (lib.attrNames config.disko.devices.zpool.tank.datasets)
            );
            missing = lib.subtractLists declared pool;
            unknown = lib.subtractLists pool declared;
          in
          [
            {
              assertion = missing == [ ];
              message = "fs-zfs-snapshots-tank: tank datasets without a snapshot policy: ${lib.concatStringsSep ", " missing}";
            }
            {
              assertion = unknown == [ ];
              message = "fs-zfs-snapshots-tank: snapshot policy names datasets not in the tank layout: ${lib.concatStringsSep ", " unknown}";
            }
          ];

        # The containers never replicate, so on a replica they have no (or
        # only stale, pre-exclusion) snapshots: `sanoid --monitor-snapshots`
        # (fs-zfs-snapshots-check) would report a permanent CRIT for them.
        services.sanoid.datasets = lib.mkIf (!config.node.fs.zfs.snapshots.autosnap) (
          lib.genAttrs containers (_: {
            monitor = false;
          })
        );

        node.fs.zfs.snapshots = {
          # Daily-written, user-authored, high-criticality data: recent-change
          # recovery matters, and the datasets are small.
          hourly = [
            "tank/delay/beans"
            "tank/delay/email"
            "tank/delay/files"
            "tank/delay/forge/data"
            "tank/delay/forge/repo"
            "tank/delay/notes"
            "tank/delay/vault"
          ];

          # Bulk / infrequently-written data, plus the container datasets.
          daily = containers ++ [
            "tank/ayako/files"
            "tank/ayako/media"
            "tank/backups/ayako"
            "tank/backups/dad"
            "tank/backups/delay"
            "tank/backups/github"
            "tank/backups/homelab"
            "tank/delay/album"
            "tank/delay/media"
            "tank/delay/music"
          ];
        };
      };
    };
}
