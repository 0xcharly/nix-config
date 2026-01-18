{ flake, ... }:
{
  config,
  lib,
  ...
}:
{
  imports = [ flake.modules.nixos.fs-zfs-replication-common ];

  options.node.fs.zfs.replication = with lib; {
    port = mkOption {
      type = types.port;
      default = 9090;
      description = ''
        The port to use over the Tailscale network to send data from the primary to replicas.
      '';
    };
  };

  config =
    let
      cfg = config.node.fs.zfs.replication;
      inherit (flake.lib.facts.nas) primary replicas;
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

      # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#options.
      services.syncoid = {
        # TODO: enable once the config has been validated.
        enable = false;

        # Run the replication everyday 15 minutes after midnight in France.
        # - Runs at midnight to reduce the risks of saturating the bandwidth of the receiving network.
        # - Runs 15 mins after the hour to reduce the risks of the snapshotting job not being done.
        interval = "Mon,Thu *-*-* 00:00:00 Europe/Paris";

        inherit (config.services.syncoid) user;
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
                  "--insecure-direct-connection=${replica.ipv4}:${cfg.port},${primary.ipv4}:${cfg.port}"
                  "--sshoption IdentitiesOnly=yes"
                  "--sshoption PasswordAuthentication=no"
                  "--sshoption KbdInteractiveAuthentication=no"
                  "--no-sync-snap" # Use existing snapshots instead of creating ephemeral ones.
                  "--skip-parent"
                ];
              };
          in
          lib.mapAttrs' mkReplicationCommand replicas;
      };
    };
}
