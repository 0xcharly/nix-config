# Setup Syncoid between NAS primary and replicas.
# Replicas are configured to accept incoming syncoid replication connections
# from the primary.
# Primary schedules replication after daily snapshotting jobs, and pushes new
# snapshots to online replicas.
{
  config,
  lib,
  pkgs,
  usrlib,
  ...
}: let
  cfg = config.modules.system.roles.nas;
  username = "syncoid";
  group = "syncoid";
in
  lib.mkIf (usrlib.bool.isTrue cfg.enable) {
    # Create service user on the replicas (it is automatically created on the sender side).
    users = lib.mkIf (usrlib.bool.isTrue cfg.replica) {
      users."${username}" = {
        isSystemUser = true;
        home = "/var/lib/${username}";
        # NOTE: Can't restrict access because syncoid needs to run multiple commands.
        # shell = "${pkgs.util-linux}/bin/nologin";
        useDefaultShell = true;
        createHome = true;
        inherit group;
        openssh.authorizedKeys.keys = lib.mkIf (usrlib.bool.isTrue cfg.replica) [
          ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
          # ''command="${pkgs.sanoid}/bin/syncoid",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIf1BY82EBfuIPmqzPhA0SXNRQ9z7zdCzE99TiqdjWmg''
        ];
      };

      groups."${group}" = {};
    };

    environment.systemPackages = with pkgs; [
      mbuffer # Syncoid optimization to smooth out network transfers.
      lzop # Syncoid optimization to reduce bytes transfered.
      sanoid
    ];

    systemd.services = lib.mkIf (usrlib.bool.isTrue cfg.replica) {
      "${username}-zfs-permissions" = {
        description = "Delegate ZFS permissions to the `${username}` user";
        wantedBy = ["multi-user.target"];
        after = ["zfs.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = let
            # The condition below is never true, but kept for documentation purposes.
            permissions =
              if (usrlib.bool.isTrue cfg.primary)
              then "send,receive,snapshot,hold,release,mount"
              else "atime,compression,create,keylocation,mount,mountpoint,receive,recordsize,snapshot,userprop"; # TODO: remove `create` after initial setup.
            zfsAllow = pkgs.writeShellApplication {
              name = "${username}-zfs-allow";
              runtimeInputs = with pkgs; [zfs];
              text = ''
                for dataset in $(zfs list -H -o name -r tank); do
                  echo "Setting ZFS permissions for $dataset…"
                  zfs allow -u ${username} ${permissions} "$dataset"
                done
              '';
            };
          in
            lib.getExe zfsAllow;
        };
      };
    };

    # https://github.com/jimsalterjrs/sanoid/wiki/Syncoid#options.
    services.syncoid = {
      enable = false;
      # TODO: enable once the config has been validated.
      # TODO: consider manually running the initial replication as it may take several days.
      # enable = cfg.primary == true;

      # Run the replication everyday 15 minutes after midnight in France.
      # - Runs at midnight to reduce the risks of saturating the bandwidth of the receiving network.
      # - Runs 15 mins after the hour to reduce the risks of the snapshotting job not being done.
      interval = "*-*-* 00:00:00 Europe/Paris";

      user = username;
      sshKey = config.age.secrets."keys/zfs_replication_ed25519_key".path;

      commands = let
        mkReplicationCommand = targetTailscaleHostname: {
          "replicate-all-datasets-${targetTailscaleHostname}" = {
            source = "tank";
            target = "${username}@${targetTailscaleHostname}.neko-danio.ts.net:tank";
            recursive = true;
            extraArgs = [
              "--sshoption IdentitiesOnly=yes"
              "--sshoption PasswordAuthentication=no"
              "--sshoption KbdInteractiveAuthentication=no"
              "--no-sync-snap" # Use existing snapshots instead of creating ephemeral ones.
              "--skip-parent"
            ];
          };
        };
        mkCommands = hosts: builtins.foldl' lib.attrsets.recursiveUpdate (builtins.map mkReplicationCommand hosts);
      in
        mkCommands ["selene"];
    };

    assertions = [
      {
        assertion = username == "syncoid";
        message = ''
          Do not change the username without updating the configuration.
          This user is only created automatically on the sender side iff it is `syncoid`.
        '';
      }
    ];
  }
