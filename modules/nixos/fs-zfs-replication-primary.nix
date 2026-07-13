{ self, ... }:
{
  flake.nixosModules.fs-zfs-replication-primary =
    { config, lib, ... }:
    {
      imports = with self.nixosModules; [ fs-zfs-replication-common ];

      config =
        let
          inherit (self.lib.facts.nas) replicas;
        in
        {
          node.fs.zfs.replication.permissions = [
            "bookmark"
            "destroy"
            "hold"
            "mount"
            "receive"
            "release"
            "send"
            "snapshot"
          ];

          # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#options
          services.syncoid = {
            # TODO: enable once the config has been validated
            enable = false;

            # Run the replication everyday 15 minutes after midnight in France
            # - Runs at midnight to reduce the risks of saturating the bandwidth of the receiving network
            # - Runs 15 mins after the hour to reduce the risks of the snapshotting job not being done
            interval = "Mon,Thu *-*-* 00:00:00 Europe/Paris";

            sshKey = config.age.secrets."keys/zfs_replication_ed25519_key".path;

            localSourceAllow = [
              "bookmark"
              "destroy"
              "hold"
              "mount"
              "receive"
              "release"
              "send"
              "snapshot"
            ];

            localTargetAllow = [
              "atime"
              "change-key"
              "compression"
              "create"
              "keylocation"
              "mount"
              "mountpoint"
              "receive"
              "recordsize"
              "rollback"
              "snapshot"
              "userprop"
              "xattr"
            ];

            commands =
              let
                mkReplicationCommand =
                  host: replica:
                  lib.nameValuePair "${host}/tank" {
                    source = "tank";
                    target = "${config.services.syncoid.user}@${replica.host}:tank";
                    recursive = true;
                    extraArgs = [
                      # KDDI <-> Orange peering caps the direct path at
                      # ~0.4 MB/s; relaying through Linode Tokyo measured
                      # ~5 MB/s end-to-end (2026-07).
                      # NOTE: `--sshoption=X=Y` (not `--sshoption X=Y`): the
                      # NixOS module escapes each element into a single argv
                      # token, and Getopt::Long only splits at the first `=`.
                      "--sshoption=ProxyJump=syncoid@jump-jp"
                      "--sshoption=IdentitiesOnly=yes"
                      "--sshoption=PasswordAuthentication=no"
                      "--sshoption=KbdInteractiveAuthentication=no"
                      "--no-sync-snap" # Use existing snapshots instead of creating ephemeral ones
                      "--skip-parent"
                    ];
                  };
              in
              lib.mapAttrs' mkReplicationCommand replicas;
          };
        };
    };
}
