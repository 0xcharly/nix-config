{ self, ... }:
{
  flake.nixosModules.fs-zfs-replication-primary =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with self.nixosModules; [ fs-zfs-replication-common ];

      config =
        let
          inherit (self.lib) facts;
          inherit (facts.nas) replicas;

          # Reports the unit's outcome to Gatus. "+" runs the hook as root: the
          # token file is root-readable only, and $SERVICE_RESULT covers every
          # outcome (non-zero exit, timeout, kill).
          mkReportResult =
            label:
            let
              mkPushRequest =
                success:
                self.lib.gatus.mkPushBasedExternalPostRequest {
                  inherit pkgs success;
                  domain = facts.services.gatus.domain;
                  tokenFile = config.age.secrets."services/gatus-external-endpoints.token".path;
                  group = "cron";
                  endpoint = "ZFS replication ${label}";
                };
            in
            self.lib.builders.mkShellApplication pkgs {
              name = "zfs-replication-report-result-${label}";
              text = ''
                if [ "''${SERVICE_RESULT:-}" = "success" ]; then
                  exec ${lib.getExe (mkPushRequest true)}
                else
                  exec ${lib.getExe (mkPushRequest false)}
                fi
              '';
            };
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
            enable = true;

            # Target cadence: daily at 00:15 Europe/Paris.
            # - Midnight Paris keeps the transfer inside FR off-hours; at ~5 MB/s
            #   via jump-jp a 100 GB delta lands in ~6h, before FR morning.
            # - :15 clears sanoid's hourly :00 run so the newest snapshots exist
            #   before syncoid scans the tree.
            # - systemd skips triggers while the unit is active: oversized
            #   transfers delay the next run instead of overlapping it.
            # TODO: arm the timer once the manual validation steps pass:
            #   interval = "*-*-* 00:15:00 Europe/Paris";
            interval = [ ];

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
                    service.serviceConfig.ExecStopPost = "+${mkReportResult replica.label}";
                  };
              in
              lib.mapAttrs' mkReplicationCommand replicas;
          };
        };
    };
}
